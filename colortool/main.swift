//
//  main.swift
//  colortool
//
//  Created by Armin Briegel on 18.12.19.
//  Copyright © 2019 Scripting OS X. All rights reserved.
//

import Cocoa


func usage() {
  print("""
colortool: a tool to create a single color png file for use in backgrounds
  usage: colortool random|dark|light|hexcode|<redvalue> <greenvalue> <bluevalue> /path/to/imagefile.png
         random:   random color is generated
         dark:     random dark color suitable for dark mode backgrounds
         light:    random light color suitable for dark mode backgrounds
         hexcode:  hexstring designating the color in the format #112233
         <redvalue> <greenvalue> <bluevalue>
                   three values from 0-100 to give the respective RBG values
""")
}

enum ColorOption : String {
  case random
  case dark
  case light
}

func randomColor(range: ClosedRange<Float>) -> NSColor {
  let red = CGFloat(Float.random(in: range))
  let green = CGFloat(Float.random(in: range))
  let blue = CGFloat(Float.random(in: range))
  return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
}

func randomColor() -> NSColor {
  return randomColor(range: 0...1)
}

func darkColor() -> NSColor {
  return randomColor(range: 0.0...0.3)
}

func lightColor() -> NSColor {
  return randomColor(range: 0.7...1.0)
}


// from https://stackoverflow.com/questions/8697205/convert-hex-color-code-to-nscolor
func colorFromString(hexString : String) -> NSColor? {
  var result : NSColor? = nil
  var colorCode : UInt32 = 0
  var redByte, greenByte, blueByte : UInt8
  
  // these two lines are for web color strings that start with a #
  // -- as in #ABCDEF; remove if you don't have # in the string
  let index1 = hexString.index(hexString.endIndex, offsetBy: -6)
  let substring1 = hexString[index1...]
  
  let scanner = Scanner(string: String(substring1))
  let success = scanner.scanHexInt32(&colorCode)
  
  if success == true {
    redByte = UInt8.init((colorCode >> 16))
    greenByte = UInt8.init((colorCode >> 8))
    blueByte = UInt8.init(colorCode) // masks off high bits
    
    result = NSColor(calibratedRed: CGFloat(redByte) / 0xff, green: CGFloat(greenByte) / 0xff, blue: CGFloat(blueByte) / 0xff, alpha: 1.0)
  }
  return result
}

func colorImage(_ color: NSColor) -> NSImage {
  let size = NSSize(width: 32, height: 32)
  let rect = NSRect(x: 0, y: 0, width: 32, height: 32)
  let image = NSImage()
  image.size = size
  image.lockFocus()
  color.drawSwatch(in: rect)
  image.unlockFocus()
  return image
}

func write(image: NSImage, toURL url: URL) {
  if let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!) {
    if let data = imageRep.representation(using: .png, properties: [:]) {
      do {
        try data.write(to: url)
      } catch {
        print("could not write to \(url.path)")
        exit(1)
      }
    }
  }

}

func parseURL(path : String) -> URL {
  let fm = FileManager.default
  let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
  let url = URL(fileURLWithPath: path, relativeTo: cwd)
  return url
}


func main() {
  // first argument is always path to binary, ignore
  let arguments = CommandLine.arguments.dropFirst()
  
  if arguments.count == 0 {
    usage()
    exit(1)
  }
  // last argument is path to file
  let filepath = arguments.last!
  
  var color: NSColor?
  
  if arguments.count == 2 {
    // first argument should be either a hexcode (start with #) or one of our options
    if arguments[0].starts(with: "#") {
      if let hexColor = colorFromString(hexString: arguments[0]) {
        color = hexColor
      } else {
        print("cannot parse \(arguments[0])")
        exit(1)
      }
    } else {
      if let option = ColorOption(rawValue: arguments[0]) {
        switch option {
        case .random:
          color = randomColor()
        case .dark:
          color = darkColor()
        case .light:
          color = lightColor()
        }
      }
    }
  } else if arguments.count == 4 {
    // three arguments are RBG values from 0-100
  } else {
    usage()
    exit(1)
  }
  
  let fileurl = URL(fileURLWithPath: filepath)
  
  let image = colorImage(color ?? NSColor.gray)
  write(image: image, toURL: fileurl)
  
}
