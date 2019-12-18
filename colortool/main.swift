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


func colorFromHex(hexString : String) -> NSColor? {
  var result : NSColor? = nil
    
  if let colorCode = Int(hexString, radix: 16) {
    let redByte = (colorCode >> 16) & 0xff
    let greenByte = (colorCode >> 8) & 0xff
    let blueByte = colorCode & 0xff
    
    let redValue = CGFloat(redByte) / 0xff
    let greenValue = CGFloat(greenByte) / 0xff
    let blueValue = CGFloat(blueByte) / 0xff

    result = NSColor(calibratedRed: redValue, green: greenValue, blue: blueValue, alpha: 1.0)
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

func parseRGBValue(_ argument: String) -> CGFloat {
  if let intValue = Int(argument) {
    if intValue >= 0 && intValue <= 100 {
      return (CGFloat(intValue) / 100)
    } else {
      print("value \(intValue) out of range 0...100")
      exit(1)
    }
  } else {
    print("\(argument) is not a valid value")
    exit(1)
  }
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
  
  if arguments.count == 1 {
    color = randomColor()
  } else if arguments.count == 2 {
    // first argument should be either a hexcode (start with #) or one of our options
    let argument1 = arguments[1]
    
    if argument1.starts(with: "#") {
      if let hexColor = colorFromHex(hexString: String(argument1.dropFirst())) {
        color = hexColor
      } else {
        print("cannot parse \(argument1)")
        exit(1)
      }
    } else {
      if let option = ColorOption(rawValue: argument1) {
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
    
    let redValue = parseRGBValue(arguments[1])
    let greenValue = parseRGBValue(arguments[2])
    let blueValue = parseRGBValue(arguments[3])

    color = NSColor(calibratedRed: redValue, green: greenValue, blue: blueValue, alpha: 1.0)
  } else {
    usage()
    exit(1)
  }
  
  let fileurl = URL(fileURLWithPath: filepath)
  
  let image = colorImage(color ?? NSColor.gray)
  write(image: image, toURL: fileurl)
}

main()
