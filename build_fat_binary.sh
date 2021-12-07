# A Script you should run to generate a binary that can be distributed via Cocoapods.
# It's easier to distribute a pre-built binary than to get Cocoapods to build
# the tool from source...
# Ultimately came from here:  https://liamnichols.eu/2020/08/01/building-swift-packages-as-a-universal-binary.html
"Building fat binary executable for Intel and M1 Macs..."
swift build -c release --arch arm64 --arch x86_64
cp ./.build/apple/Products/Release/colorgen ./bin/colorgen