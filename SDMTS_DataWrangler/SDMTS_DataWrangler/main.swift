//
//  main.swift
//  SDMTS_DataWrangler
//
//  Created by Will An on 8/9/17.
//  Copyright © 2017 Will An. All rights reserved.
//

import Foundation

let myIO = IO(dictionaryPath: CommandLine.arguments[1] as NSString)
let myStaticDict = StaticDictionaryCollection(resourcePath: myIO.dictionaryPath)
myStaticDict.stop_times()

