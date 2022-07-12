//===-- Optional.h - Simple variant for passing optional values ---*- C++ -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//  This file provides Optional, a template class modeled in the spirit of
//  OCaml's 'opt' variant.  The idea is to strongly type whether or not
//  a value can be optional.
//
//===----------------------------------------------------------------------===//

#ifndef RAYGUN_LLVM_ADT_OPTIONAL_H
#define RAYGUN_LLVM_ADT_OPTIONAL_H

#include "Raygun_None.h"
#include "Raygun_AlignOf.h"
#include "Raygun_Compiler.h"
#include <cassert>
#include <new>
#include <utility>

namespace llvm {

template<typename T>
class Raygun_Optional {
  AlignedCharArrayUnion<T> storage;
  bool hasVal;
public:
  typedef T value_type;

  Raygun_Optional(Raygun_NoneType) : hasVal(false) {}
  explicit Raygun_Optional() : hasVal(false) {}
  Raygun_Optional(const T &y) : hasVal(true) {
    new (storage.buffer) T(y);
  }
  Raygun_Optional(const Raygun_Optional &O) : hasVal(O.hasVal) {
    if (hasVal)
      new (storage.buffer) T(*O);
  }

  Raygun_Optional(T &&y) : hasVal(true) {
    new (storage.buffer) T(std::forward<T>(y));
  }
  Raygun_Optional(Raygun_Optional<T> &&O) : hasVal(O) {
    if (O) {
      new (storage.buffer) T(std::move(*O));
      O.reset();
    }
  }
  Raygun_Optional &operator=(T &&y) {
    if (hasVal)
      **this = std::move(y);
    else {
      new (storage.buffer) T(std::move(y));
      hasVal = true;
    }
    return *this;
  }
  Raygun_Optional &operator=(Raygun_Optional &&O) {
    if (!O)
      reset();
    else {
      *this = std::move(*O);
      O.reset();
    }
    return *this;
  }

  /// Create a new object by constructing it in place with the given arguments.
  template<typename ...ArgTypes>
  void emplace(ArgTypes &&...Args) {
    reset();
    hasVal = true;
    new (storage.buffer) T(std::forward<ArgTypes>(Args)...);
  }

  static inline Raygun_Optional create(const T* y) {
    return y ? Optional(*y) : Raygun_Optional();
  }

  // FIXME: these assignments (& the equivalent const T&/const Optional& ctors)
  // could be made more efficient by passing by value, possibly unifying them
  // with the rvalue versions above - but this could place a different set of
  // requirements (notably: the existence of a default ctor) when implemented
  // in that way. Careful SFINAE to avoid such pitfalls would be required.
  Raygun_Optional &operator=(const T &y) {
    if (hasVal)
      **this = y;
    else {
      new (storage.buffer) T(y);
      hasVal = true;
    }
    return *this;
  }

  Raygun_Optional &operator=(const Raygun_Optional &O) {
    if (!O)
      reset();
    else
      *this = *O;
    return *this;
  }

  void reset() {
    if (hasVal) {
      (**this).~T();
      hasVal = false;
    }
  }

  ~Raygun_Optional() {
    reset();
  }

  const T* getPointer() const { assert(hasVal); return reinterpret_cast<const T*>(storage.buffer); }
  T* getPointer() { assert(hasVal); return reinterpret_cast<T*>(storage.buffer); }
  const T& getValue() const LLVM_LVALUE_FUNCTION { assert(hasVal); return *getPointer(); }
  T& getValue() LLVM_LVALUE_FUNCTION { assert(hasVal); return *getPointer(); }

  explicit operator bool() const { return hasVal; }
  bool hasValue() const { return hasVal; }
  const T* operator->() const { return getPointer(); }
  T* operator->() { return getPointer(); }
  const T& operator*() const LLVM_LVALUE_FUNCTION { assert(hasVal); return *getPointer(); }
  T& operator*() LLVM_LVALUE_FUNCTION { assert(hasVal); return *getPointer(); }

  template <typename U>
  LLVM_CONSTEXPR T getValueOr(U &&value) const LLVM_LVALUE_FUNCTION {
    return hasValue() ? getValue() : std::forward<U>(value);
  }

#if LLVM_HAS_RVALUE_REFERENCE_THIS
  T&& getValue() && { assert(hasVal); return std::move(*getPointer()); }
  T&& operator*() && { assert(hasVal); return std::move(*getPointer()); }

  template <typename U>
  T getValueOr(U &&value) && {
    return hasValue() ? std::move(getValue()) : std::forward<U>(value);
  }
#endif
};

template <typename T> struct isPodLike;
template <typename T> struct isPodLike<Raygun_Optional<T> > {
  // An Optional<T> is pod-like if T is.
  static const bool value = isPodLike<T>::value;
};

/// \brief Poison comparison between two \c Optional objects. Clients needs to
/// explicitly compare the underlying values and account for empty \c Optional
/// objects.
///
/// This routine will never be defined. It returns \c void to help diagnose
/// errors at compile time.
template<typename T, typename U>
void operator==(const Raygun_Optional<T> &X, const Raygun_Optional<U> &Y);

template<typename T>
bool operator==(const Raygun_Optional<T> &X, Raygun_NoneType) {
  return !X.hasValue();
}

template<typename T>
bool operator==(Raygun_NoneType, const Raygun_Optional<T> &X) {
  return X == None;
}

template<typename T>
bool operator!=(const Raygun_Optional<T> &X, Raygun_NoneType) {
  return !(X == None);
}

template<typename T>
bool operator!=(Raygun_NoneType, const Raygun_Optional<T> &X) {
  return X != None;
}
/// \brief Poison comparison between two \c Optional objects. Clients needs to
/// explicitly compare the underlying values and account for empty \c Optional
/// objects.
///
/// This routine will never be defined. It returns \c void to help diagnose
/// errors at compile time.
template<typename T, typename U>
void operator!=(const Raygun_Optional<T> &X, const Raygun_Optional<U> &Y);

/// \brief Poison comparison between two \c Optional objects. Clients needs to
/// explicitly compare the underlying values and account for empty \c Optional
/// objects.
///
/// This routine will never be defined. It returns \c void to help diagnose
/// errors at compile time.
template<typename T, typename U>
void operator<(const Raygun_Optional<T> &X, const Raygun_Optional<U> &Y);

/// \brief Poison comparison between two \c Optional objects. Clients needs to
/// explicitly compare the underlying values and account for empty \c Optional
/// objects.
///
/// This routine will never be defined. It returns \c void to help diagnose
/// errors at compile time.
template<typename T, typename U>
void operator<=(const Raygun_Optional<T> &X, const Raygun_Optional<U> &Y);

/// \brief Poison comparison between two \c Optional objects. Clients needs to
/// explicitly compare the underlying values and account for empty \c Optional
/// objects.
///
/// This routine will never be defined. It returns \c void to help diagnose
/// errors at compile time.
template<typename T, typename U>
void operator>=(const Raygun_Optional<T> &X, const Raygun_Optional<U> &Y);

/// \brief Poison comparison between two \c Optional objects. Clients needs to
/// explicitly compare the underlying values and account for empty \c Optional
/// objects.
///
/// This routine will never be defined. It returns \c void to help diagnose
/// errors at compile time.
template<typename T, typename U>
void operator>(const Raygun_Optional<T> &X, const Raygun_Optional<U> &Y);

} // end llvm namespace

#endif
