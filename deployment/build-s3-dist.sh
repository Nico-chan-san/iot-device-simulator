#!/bin/bash
#
# This assumes all of the OS-level configuration has been completed and git repo has already been cloned
#
# This script should be run from the repo's deployment directory
# cd deployment
# ./build-s3-dist.sh source-bucket-base-name version-code
#
# Paramenters:
#  - source-bucket-base-name: Name for the S3 bucket location where the template will source the Lambda
#    code from. The template will append '-[region_name]' to this bucket name.
#    For example: ./build-s3-dist.sh solutions v1.0.0
#    The template will then expect the source code to be located in the solutions-[region_name] bucket
#
#  - version-code: version of the package

# Check to see if input has been provided:
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide the base source bucket name for the S3 bucket location where the template will source the Lambda
#    code from—the template will append '-[region_name]' to this bucket name—followed by the version of the package."
    echo "For example: ./build-s3-dist.sh solutions v1.0.0"
    echo "The template will then expect the source code to be located in the solutions-[region_name] bucket."
    exit 1
fi

# Get reference for all important folders
template_dir="$PWD"
build_dist_dir="$template_dir/dist"
source_dir="$template_dir/../source"

echo "------------------------------------------------------------------------------"
echo "[Init] Clean old dist folder"
echo "------------------------------------------------------------------------------"
echo "rm -rf $build_dist_dir"
rm -rf $build_dist_dir
echo "mkdir -p $build_dist_dir"
mkdir -p $build_dist_dir
echo "mkdir -p $build_dist_dir/console"
mkdir -p $build_dist_dir/console
echo "mkdir -p $build_dist_dir/routes"
mkdir -p $build_dist_dir/routedata/routes

echo "------------------------------------------------------------------------------"
echo "[Packing] Templates"
echo "------------------------------------------------------------------------------"
echo "cp $template_dir/iot-device-simulator.yaml $build_dist_dir/iot-device-simulator.template"
cp $template_dir/iot-device-simulator.yaml $build_dist_dir/iot-device-simulator.template

echo "Updating code source bucket in template with $1"
replace="s/%%BUCKET_NAME%%/$1/g"
echo "sed -i '' -e $replace $build_dist_dir/iot-device-simulator.template"
sed -i '' -e $replace $build_dist_dir/iot-device-simulator.template
replace="s/%%VERSION%%/$2/g"
echo "sed -i '' -e $replace $build_dist_dir/iot-device-simulator.template"
sed -i '' -e $replace $build_dist_dir/iot-device-simulator.template
replace="s/%%SOLUTION_NAME%%/$1/g"
echo "sed -i '' -e $replace $build_dist_dir/iot-device-simulator.template"
sed -i '' -e $replace $build_dist_dir/iot-device-simulator.template

echo "------------------------------------------------------------------------------"
echo "[Rebuild] Console"
echo "------------------------------------------------------------------------------"
# build and copy console distribution files
cd $source_dir/console
rm -r ./dist
npm install
./node_modules/@angular/cli/bin/ng build --prod --aot=false
cp -r ./dist/** $build_dist_dir/console
rm $build_dist_dir/console/assets/appVariables.js

echo "------------------------------------------------------------------------------"
echo "[Rebuild] Services - Admin"
echo "------------------------------------------------------------------------------"
cd $source_dir/services/admin
npm run build
cp ./dist/iot-sim-admin-service.zip $build_dist_dir/iot-sim-admin-service.zip

echo "------------------------------------------------------------------------------"
echo "[Rebuild] Services - Device"
echo "------------------------------------------------------------------------------"
cd $source_dir/services/device
npm run build
cp ./dist/iot-sim-device-service.zip $build_dist_dir/iot-sim-device-service.zip

echo "------------------------------------------------------------------------------"
echo "[Rebuild] Services - Profile"
echo "------------------------------------------------------------------------------"
cd $source_dir/services/profile
npm run build
cp ./dist/iot-sim-profile-service.zip $build_dist_dir/iot-sim-profile-service.zip

echo "------------------------------------------------------------------------------"
echo "[Rebuild] Services - Metrics"
echo "------------------------------------------------------------------------------"
cd $source_dir/services/metrics
npm run build
cp ./dist/iot-sim-metrics-service.zip $build_dist_dir/iot-sim-metrics-service.zip

echo "------------------------------------------------------------------------------"
echo "[Rebuild] Resource - Custom Helper"
echo "------------------------------------------------------------------------------"
cd $source_dir/resources/helper
npm run build
cp ./dist/iot-sim-helper.zip $build_dist_dir/iot-sim-helper.zip

echo "------------------------------------------------------------------------------"
echo "[Manifest] Generating console manifest"
echo "------------------------------------------------------------------------------"
cd $template_dir/manifest-generator
npm install --production
node app.js --target ../dist/console --output ../dist/site-manifest.json

echo "------------------------------------------------------------------------------"
echo "[Routes] Generating route manifest"
echo "------------------------------------------------------------------------------"
cd $source_dir/resources/routes
cp -r $source_dir/resources/routes/** $build_dist_dir/routedata/routes
cd $template_dir/manifest-generator
node app.js --target ../dist/routedata --output ../dist/routes-manifest.json
