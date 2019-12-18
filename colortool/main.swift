//
//  main.swift
//  colortool
//
//  Created by Armin Briegel on 18.12.19.
//  Copyright © 2019 Scripting OS X. All rights reserved.
//

import Cocoa

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

let fileurl = URL(fileURLWithPath: "/Users/armin/Desktop/color.png")

let color = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)

let image = colorImage(color)
write(image: image, toURL: fileurl)



