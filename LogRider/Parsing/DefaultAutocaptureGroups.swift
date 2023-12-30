//
//  DefaultAutocaptureGroups.swift
//  Tile
//
//  Created by Marin Todorov on 10/30/22.
//

import Foundation

let defaultAutoCaptureGroups = [
    AutoCaptureGroup(
        id: "colon-pair",
        regex: "(.+)\\s*\\:\\s+(.+)",
        name: "Colon separated values",
        description: "Colon separated values",
        examples: [
            "Offset: 345.79",
            "Enabled: true",
            "Opened ranges: 21",
            "Last user login: 2022-01-01 11:14"
        ],
        displayText: "(.heading): [Text or number]",
        tokenTypes: [ .heading, .value ]
    ),
    AutoCaptureGroup(
        id: "value-in-quotes",
        regex: "(.+)\\s+'(.+)'",
        name: "Values in quotes",
        description: "Values in quotes",
        examples: [
            "Variant 'This is the value'",
            "Current value is '3045'",
            "Logged user   'Admin'",
            "Active 'YES'"
        ],
        displayText: "(.heading) '[Text]'",
        tokenTypes: [ .heading, .value ]
    ),
    AutoCaptureGroup(
        id: "variable",
        regex: "(.+)\\s+=\\s+(.+)",
        name: "Values separated by equals sign",
        description: "Values separated by equals sign",
        examples: [
            "name = Peter",
            "retainCount = 1,304",
            "isEnabled = true",
            "isActive = NO"
        ],
        displayText: "(.heading) = [Text or number]",
        tokenTypes: [ .heading, .value ]
    )
]

let activityAutoCaptureGroup = AutoCaptureGroup(
    id: "activity",
    regex: "(.+)",
    name: "Input Activity",
    description: "Matches any input",
    examples: [
        "Text"
    ],
    displayText: "[Any Input Text]",
    tokenTypes: [ .value ]
)

let signpostAutoCaptureGroup = AutoCaptureGroup(
    id: "signpost",
    regex: "signpostEvent:(.+):(.+)",
    name: "Signpost Intervals",
    description: "Matches signpost intervals",
    examples: [
        "Text"
    ],
    displayText: " (.heading) [Intervals]",
    isEnabled: true,
    tokenTypes: [ .heading, .value ]
)
