# Bluetooth Stylus SDK for iOS

## Version 2.2.5

## History

### 2.2.5  01-Jun-2020
    - Rebuilt zip file

### 2.2.4  07-Nov-2019
    - Add Support for iPhone 11, iPhone 11 Pro, iPhone 11 Pro Max, and iPad 10.2
    - Know Issue:
          When using one of the Wacom Pens on the iPad 10.2 that is running iPadOS 13.2, sections of the drawn line are blank.
          This behavior is caused by Apple’s iPadOS sending touchesCancel events rather that touchesMoved events.
          A defect was filed with Apple. The BluetoothStylusSdk helps fix this behavior, but is ineffective when the pen is perpendicular to the iPad.
      
### 2.2.1 - 17 January 2019
    - Add Support for iPad Pro 12.9 (3nd gen), iPad Pro 11, iPhone XS,
    - iPhone XS Max, and iPhone XR
    - Fixed Defect: removed the dialog to "install the Wacom Stylus Update.app" as this app is no longer available at the App Store.

### 1.0 - date (e.g. 17 Jan 2019)
    - Initial public release.
  