#!/bin/sh

#  sign.sh
#  raygun4apple
#
#  Created by RaygunDev on 6/8/18.
#  

sudo productsign --sign "Developer ID Installer: Mindscape Limited (7AK2557CXR)" build/raygun4appleInstaller.pkg build/raygun4apple.pkg
