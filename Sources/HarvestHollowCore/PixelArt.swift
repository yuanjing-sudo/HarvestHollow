import Foundation

// MARK: - Pixel art primitives

public struct PixelCell: Hashable, Sendable {
    public let x: Int
    public let y: Int
    public let hex: String

    public init(x: Int, y: Int, hex: String) {
        self.x = x
        self.y = y
        self.hex = hex
    }
}

/// A sprite is a small grid of coloured squares. Every visible cell is one
/// square; the "." character is transparent.
public struct PixelSprite: Sendable {
    public let key: String
    public let width: Int
    public let height: Int
    public let palette: [Character: String]
    public let rows: [String]
    public let cells: [PixelCell]

    public init(key: String, width: Int, palette: [Character: String], rows: [String]) {
        self.key = key
        self.width = width
        self.height = rows.count
        self.palette = palette
        self.rows = rows

        var cells: [PixelCell] = []
        cells.reserveCapacity(width * rows.count)
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() where character != "." {
                if let hex = palette[character] {
                    cells.append(PixelCell(x: x, y: y, hex: hex))
                }
            }
        }
        self.cells = cells
    }

    public var coloredCellCount: Int { cells.count }

    public var uniqueColorCount: Int {
        Set(cells.map(\.hex)).count
    }

    /// A compact ASCII rendering used by tests and the terminal sprite browser.
    public var asciiArt: String {
        rows.joined(separator: "\n")
    }
}

public enum SpriteLibrary {
    public static let all: [String: PixelSprite] = {
        let sprites: [PixelSprite] = animals + crops + furniture + items + fish + dishes
        return Dictionary(uniqueKeysWithValues: sprites.map { ($0.key, $0) })
    }()

    public static func sprite(named key: String) -> PixelSprite? {
        all[key]
    }

    public static func animal(_ speciesID: String) -> PixelSprite? {
        all["animal.\(speciesID)"]
    }

    public static func crop(_ cropID: String) -> PixelSprite? {
        all["crop.\(cropID)"]
    }

    public static func furniture(_ itemID: String) -> PixelSprite? {
        all[itemID]
    }

    public static func fish(_ fishID: String) -> PixelSprite? {
        all["fish.\(fishID)"]
    }

    public static func dish(_ itemID: String) -> PixelSprite? {
        all[itemID]
    }

    public static var allSprites: [PixelSprite] {
        all.values.sorted { $0.key < $1.key }
    }

    // MARK: Animals

    private static let animals: [PixelSprite] = [
        PixelSprite(
            key: "animal.pig",
            width: 14,
            palette: [
                "o": "3E2A2A", "p": "F3A6B8", "P": "FFCBD6", "d": "D97B92",
                "s": "E8879F", "n": "B95F78", "w": "FFFFFF", "k": "2B1B1B"
            ],
            rows: [
                "..............",
                "...oo....oo...",
                "..oppo..oppo..",
                "..oppppppppo..",
                ".oppppppppppo.",
                ".oppppppppppo.",
                ".opwkppppkwpo.",
                ".opdppppppdpo.",
                ".opppssssppo..",
                ".opppsnnsppo..",
                "..opppppppo...",
                "..oo...oo....."
            ]
        ),
        PixelSprite(
            key: "animal.chicken",
            width: 14,
            palette: [
                "o": "4A3325", "w": "FFF7E8", "s": "E7DAC2", "r": "E05252",
                "R": "B23A3A", "y": "F2B544", "k": "2B1B1B"
            ],
            rows: [
                "..............",
                "......rr......",
                ".....rRrr.....",
                "....owwwwo....",
                "...owwwwwwo...",
                "..owwwwwwwwo..",
                "..owkwwwwkwo..",
                "..owwwyywwwo..",
                "..oswwrrwwso..",
                ".oswwwwwwwwso.",
                ".oswwwwwwwwso.",
                "..yy......yy.."
            ]
        ),
        PixelSprite(
            key: "animal.duck",
            width: 14,
            palette: [
                "o": "3D3226", "w": "FFF9EC", "s": "E8DDC6", "y": "F0A93B",
                "Y": "FFD37A", "k": "2B1B1B", "g": "4E8A5A", "G": "79B86E",
                "b": "4F7FA8", "B": "8FC3DD"
            ],
            rows: [
                "..............",
                "....oooo......",
                "...oggggo.....",
                "..ogGggggo....",
                "..ogkgggggo...",
                "..oggggggggo..",
                ".oyywwwwwwwwo.",
                ".oyywwwwwwwwwo",
                ".owwwwwbbwwwwo",
                "..oswwwwwwso..",
                "..oo.wwww.oo..",
                "....yy.yy....."
            ]
        ),
        PixelSprite(
            key: "animal.cow",
            width: 14,
            palette: [
                "o": "3A2A26", "w": "F8F3E7", "s": "DCD1BE", "k": "2B2622",
                "p": "F2A7B0", "h": "E4C27B", "u": "6B5140"
            ],
            rows: [
                "..............",
                "..h........h..",
                ".hoh......hoh.",
                ".ohho....ohho.",
                "..owwoooowwo..",
                ".owwwwwwwwwwo.",
                ".owkkwwwwkkwo.",
                ".okkwwppwwkko.",
                ".owwwppppwwwo.",
                "..owwwhhwwwo..",
                "..ow....wo....",
                "..oo....oo...."
            ]
        ),
        PixelSprite(
            key: "animal.sheep",
            width: 14,
            palette: [
                "o": "4A3B33", "c": "F3EAD8", "C": "FFF9EC", "s": "D9CBB4",
                "f": "5A4A42", "k": "2B1B1B", "p": "E8A7A7", "h": "5A4A42"
            ],
            rows: [
                "....cc..cc....",
                "..ccCCccCCcc..",
                ".cCCCCCCCCCCc.",
                "cCCCCCCCCCCCCc",
                "cCCpffffffpCCc",
                "cCCpfkffkfpCCc",
                "cCCpffffffpCCc",
                "cCCCCCCCCCCCCc",
                ".cCCCCCCCCCCc.",
                "..cCCCCCCCCc..",
                "..ff......ff..",
                "..hh......hh.."
            ]
        ),
        PixelSprite(
            key: "animal.goat",
            width: 14,
            palette: [
                "o": "40332A", "c": "F2E8D5", "C": "FFF8EA", "s": "D8C9B1",
                "k": "2B1B1B", "p": "D9A6A6", "h": "D8C08A", "b": "DED5C2"
            ],
            rows: [
                "..............",
                "..h........h..",
                ".hoh......hoh.",
                ".ohho....ohho.",
                "..occcccccco..",
                ".occcccccccco.",
                ".occckcckccco.",
                ".occcccccccco.",
                ".occcppppccco.",
                "...obbbbbbo...",
                "..oc.....co...",
                "..oo.....oo..."
            ]
        ),
        PixelSprite(
            key: "animal.bee",
            width: 14,
            palette: [
                "o": "3B2E1E", "y": "F6C945", "Y": "FFE38A", "k": "2E2519",
                "w": "DDF1FF", "W": "FFFFFF", "a": "6B5A2E"
            ],
            rows: [
                "..............",
                "..a........a..",
                "...a......a...",
                "....oooooo....",
                "..ooyyyyyyoo..",
                ".oyyykkkkyyyo.",
                "wwoyykkkkyyoww",
                "wwyyyykkyyyyww",
                ".oyyykkkkyyyo.",
                "..ooyyyyyyoo..",
                "...o.oooo.o...",
                "....o....o...."
            ]
        )
    ]

    // MARK: Crops

    private static let crops: [PixelSprite] = [
        PixelSprite(
            key: "crop.wheat",
            width: 10,
            palette: [
                "o": "6B5A2E", "g": "6FA84F", "G": "9BD06C", "y": "E8C15A", "Y": "F6E08A"
            ],
            rows: [
                "...y..y...",
                "..yYy.yYy.",
                "..ygy.ygy.",
                "...g...g..",
                "...g.g.g..",
                "..g.gg.g..",
                "...gg.g...",
                "...g.g....",
                "...g.g....",
                "...o.o...."
            ]
        ),
        PixelSprite(
            key: "crop.carrot",
            width: 10,
            palette: [
                "o": "8C421D", "O": "F08A3C", "R": "FFB25E", "g": "5FA448", "G": "8DD06A"
            ],
            rows: [
                "....g.....",
                "..g.g.g...",
                ".g..G..g..",
                "..ggggg...",
                "...ooo....",
                "...oRo....",
                "..oOROo...",
                "..oOROo...",
                "...oRo....",
                "....o....."
            ]
        ),
        PixelSprite(
            key: "crop.tomato",
            width: 10,
            palette: [
                "o": "7A2B22", "r": "D94A3D", "R": "F27063", "g": "4F8A3C", "G": "7DBF5B"
            ],
            rows: [
                "....g.....",
                "..g.G.g...",
                ".ggggggg..",
                ".orrrrro..",
                "orRrrrRro.",
                "orrrrrrro.",
                "orrrrrrro.",
                ".orrrrro..",
                "..ooooo...",
                ".........."
            ]
        ),
        PixelSprite(
            key: "crop.strawberry",
            width: 10,
            palette: [
                "o": "7A2B35", "r": "E04458", "R": "FF6B7A", "g": "4F8A3C",
                "G": "7DBF5B", "w": "FFF2D0", "y": "F5D76E"
            ],
            rows: [
                "....g.....",
                "...gGg....",
                "..gGGGg...",
                ".orrrrro..",
                "orrwrrrro.",
                "orrrrrrro.",
                "orrrrrrro.",
                ".orrrrro..",
                "..orrrro..",
                "...ooo...."
            ]
        ),
        PixelSprite(
            key: "crop.sunflower",
            width: 10,
            palette: [
                "o": "8A6B20", "y": "F2C744", "Y": "FFE47A", "b": "6B4A24",
                "g": "4F8A3C", "G": "7DBF5B"
            ],
            rows: [
                "...yyy....",
                "..yYYYy...",
                ".yYbbbYy..",
                ".yYbbbYy..",
                "..yYYYy...",
                "...yyy....",
                "....g.....",
                "....g.....",
                "..g.g.....",
                "....g....."
            ]
        ),
        PixelSprite(
            key: "crop.corn",
            width: 10,
            palette: [
                "o": "6B5A2E", "y": "E8C15A", "Y": "F7E39A", "g": "4F8A3C", "G": "7DBF5B"
            ],
            rows: [
                "...g.g....",
                "..g.gg....",
                "..ggggg...",
                "...yyy....",
                "..yYYYy...",
                "..yYyYy...",
                "..yYyYy...",
                "...yyy....",
                "...g.g....",
                "...g.g...."
            ]
        ),
        PixelSprite(
            key: "crop.lavender",
            width: 10,
            palette: [
                "o": "4F5A2E", "p": "8E6BC4", "P": "B79BE0", "g": "5A8A4C", "G": "7DBF5B"
            ],
            rows: [
                "...p..p...",
                "..pPp.pPp.",
                "..pPp.pPp.",
                "...p..p...",
                "...g..g...",
                "...g..g...",
                "..g.g.g...",
                "...g.g....",
                "...g.g....",
                "...o.o...."
            ]
        ),
        PixelSprite(
            key: "crop.pumpkin",
            width: 10,
            palette: [
                "o": "8A3B12", "O": "E87524", "R": "F9A44A", "g": "4F7D3B", "G": "7DBF5B"
            ],
            rows: [
                "....gg....",
                "...gGGg...",
                "..oooooo..",
                ".oOoRRoOo.",
                "oOOoRRoOOo",
                "oOoORROoOo",
                "oOoORROoOo",
                "oOOoRRoOOo",
                ".oOOOOOOo.",
                "..oooooo.."
            ]
        ),
        PixelSprite(
            key: "crop.moonberry",
            width: 10,
            palette: [
                "o": "26304A", "g": "3E5A54", "G": "5E8A78", "b": "4E6FC4",
                "B": "8FB4FF", "w": "EAF2FF"
            ],
            rows: [
                "....g.....",
                "..g.G.g...",
                ".ggggggg..",
                ".gGgbGgg..",
                "gGbbBbbGg.",
                "gbbBbBbbg.",
                "gbbBbbbGg.",
                ".gbbbbGg..",
                "..ggggg...",
                ".........."
            ]
        )
    ]

    // MARK: Furniture

    private static let furniture: [PixelSprite] = [
        PixelSprite(
            key: "furniture.chair",
            width: 12,
            palette: [
                "o": "5A3A24", "w": "C98B5E", "W": "E8B57C", "s": "9A5E3A"
            ],
            rows: [
                "..oooooo....",
                "..oWWWWo....",
                "..oWwwWo....",
                "..oWwwWo....",
                "..oWWWWo....",
                "..oooooooo..",
                "..oWWWWWWo..",
                "..oWwwwwwo..",
                "..oWo..oWo..",
                "..ooo..ooo.."
            ]
        ),
        PixelSprite(
            key: "furniture.plant",
            width: 12,
            palette: [
                "o": "3F6B3A", "g": "5FA448", "G": "8DD06A", "p": "B86B4B", "P": "D98E6A"
            ],
            rows: [
                "....g.G.....",
                "..g.GGg.G...",
                ".gGGgGGGg...",
                "..gGGGGg....",
                "....gG......",
                "....g.......",
                "...oooo.....",
                "...oPPo.....",
                "...oPpo.....",
                "...oooo....."
            ]
        ),
        PixelSprite(
            key: "furniture.lamp",
            width: 12,
            palette: [
                "o": "5A4A32", "y": "F5D76E", "Y": "FFF0A8", "s": "C9A94A", "w": "8A6B3A"
            ],
            rows: [
                "....oooo....",
                "...oyYYyo...",
                "..oyYYYYyo..",
                ".oyYYYYYYyo.",
                ".oooooooooo.",
                ".....ww.....",
                ".....ww.....",
                ".....ww.....",
                "....oooo....",
                "...oooooo..."
            ]
        ),
        PixelSprite(
            key: "furniture.teddy",
            width: 12,
            palette: [
                "o": "5A3A24", "b": "B57A47", "B": "D9A26A", "k": "2B1B1B",
                "p": "E8A7A7", "w": "FFF9EC"
            ],
            rows: [
                "..oo....oo..",
                ".oBBo..oBBo.",
                ".oBBBBBBBBo.",
                ".oBkBBBBkBo.",
                ".oBBBBBBBBo.",
                ".oBppBBppBo.",
                "..oBBBBBBo..",
                "..oBBBBBBo..",
                "..oBo..oBo..",
                "..oo....oo.."
            ]
        ),
        PixelSprite(
            key: "furniture.rug",
            width: 12,
            palette: [
                "o": "7A3A35", "r": "C95B4E", "R": "E89B72", "y": "E8C15A", "b": "4F6D8A"
            ],
            rows: [
                "oooooooooooo",
                "orrrrrrrrrro",
                "orRrrrrrrRro",
                "orrryyyyrrro",
                "orRryyyyRrro",
                "orrryyyyrrro",
                "orRrrrrrrRro",
                "orrrrrrrrrro",
                "oooooooooooo",
                "............"
            ]
        ),
        PixelSprite(
            key: "furniture.table",
            width: 12,
            palette: [
                "o": "5A3A24", "w": "B57A47", "W": "D9A26A", "c": "FFF9EC", "g": "7DBF5B"
            ],
            rows: [
                "............",
                "..o......o..",
                "..o.cc...o..",
                "..o.gg...o..",
                ".oWWWWWWWWo.",
                ".owwwwwwwwo.",
                ".oooooooooo.",
                "..o......o..",
                "..o......o..",
                "..o......o.."
            ]
        ),
        PixelSprite(
            key: "furniture.painting",
            width: 12,
            palette: [
                "o": "5A3A24", "y": "F5D76E", "g": "6FA84F", "G": "9BD06C",
                "b": "8FB4FF", "w": "FFF9EC"
            ],
            rows: [
                "oooooooooooo",
                "oyyyyyyyyyyo",
                "oybbbbbbbyyo",
                "oybbbwbbbbyo",
                "oybbbbbbggyo",
                "oyggggggggyo",
                "oyGGGGGGGGyo",
                "oyyyyyyyyyyo",
                "oooooooooooo",
                "............"
            ]
        ),
        PixelSprite(
            key: "furniture.bookshelf",
            width: 12,
            palette: [
                "o": "5A3A24", "w": "B57A47", "r": "C95B4E", "b": "4F6D8A",
                "g": "6FA84F", "y": "E8C15A", "p": "8E6BC4"
            ],
            rows: [
                "oooooooooooo",
                "owwwwwwwwwwo",
                "owrrbbyyppwo",
                "owwwwwwwwwwo",
                "oooooooooooo",
                "owbbggrryywo",
                "owwwwwwwwwwo",
                "oooooooooooo",
                "owrrbbggyywo",
                "owwwwwwwwwwo"
            ]
        ),
        PixelSprite(
            key: "furniture.fireplace",
            width: 12,
            palette: [
                "o": "4A2E24", "b": "9A5E4A", "B": "C97B63", "y": "F5C542",
                "Y": "FFF0A8", "r": "E05252", "k": "2B1B1B"
            ],
            rows: [
                "oooooooooooo",
                "obBBBBBBBBbo",
                "obBBBBBBBBbo",
                "oooooooooooo",
                "obBBBBBBBBbo",
                "obBBkyyBBbbo",
                "obBkyYyBBbbo",
                "obBkyYyBBbbo",
                "obBBkyyBBbbo",
                "oooooooooooo"
            ]
        ),
        PixelSprite(
            key: "furniture.aquarium",
            width: 12,
            palette: [
                "o": "3A4A5A", "w": "A8DDF0", "W": "DDF5FF", "b": "4F8AAE",
                "y": "F5C542", "g": "5FA448", "G": "8DD06A"
            ],
            rows: [
                "oooooooooooo",
                "oWWWWWWWWWWo",
                "oWwwwwwwwwWo",
                "oWwwyywwwwWo",
                "oWwyyyywwgWo",
                "oWwwwwwwgGWo",
                "oWwwwwwwwwWo",
                "oWggwwwwwwWo",
                "oWWWWWWWWWWo",
                "oooooooooooo"
            ]
        ),
        PixelSprite(
            key: "furniture.bed",
            width: 12,
            palette: [
                "o": "5A3A24", "w": "B57A47", "W": "D9A26A", "c": "FFF9EC",
                "r": "C95B4E", "p": "E8A7A7"
            ],
            rows: [
                "oooooooooooo",
                "owwwwwwwwwwo",
                "occcccccrrro",
                "occccccrrrro",
                "oWWWWWWWWWWo",
                "oWppWWWWppWo",
                "oWppWWWWppWo",
                "oWWWWWWWWWWo",
                "oooooooooooo",
                "ow........wo"
            ]
        ),
        PixelSprite(
            key: "furniture.piano",
            width: 12,
            palette: [
                "o": "2B1B1B", "k": "3E2A2A", "w": "FFF9EC", "W": "FFF9EC", "s": "8A8A8A", "y": "E8C15A"
            ],
            rows: [
                "............",
                "oooooooooooo",
                "okkkkkkkkkko",
                "okkkkkkkkkko",
                "oWWWWWWWWWWo",
                "owsWsWsWsWwo",
                "oWWWWWWWWWWo",
                "oWWWWWWWWWWo",
                "oooooooooooo",
                "..o......o.."
            ]
        ),
        PixelSprite(
            key: "furniture.vase",
            width: 12,
            palette: [
                "o": "5A3A24", "v": "8E6BC4", "V": "B79BE0", "g": "5FA448",
                "G": "8DD06A", "y": "F5D76E"
            ],
            rows: [
                "...gg.yy....",
                "..gGG.gG....",
                "..oVVo......",
                "..oVVVo.....",
                "...oVVo.....",
                "...oVVo.....",
                "..oVVVVo....",
                "..oVVVVo....",
                "...oooo.....",
                "............"
            ]
        ),
        PixelSprite(
            key: "furniture.trophy",
            width: 12,
            palette: [
                "o": "8A6B20", "y": "F5D76E", "Y": "FFF0A8", "b": "B58A2A", "s": "6B4A24"
            ],
            rows: [
                "..oooooooo..",
                "..oyYYYYyo..",
                "..oyYYYYyo..",
                "..oyYYYYyo..",
                "...oyYYyo...",
                "....oyyo....",
                ".....oo.....",
                "....oooo....",
                "...obbbbo...",
                "..oooooooo.."
            ]
        )
    ]

    // MARK: Items

    private static let items: [PixelSprite] = [
        PixelSprite(
            key: "item.egg",
            width: 10,
            palette: ["o": "6B5A4A", "w": "EDE3D0", "W": "FFFDF5"],
            rows: [
                "..........",
                "....oo....",
                "...owWo...",
                "..owWWWo..",
                "..oWWWWo..",
                "..oWWWWo..",
                "..oWwwWo..",
                "...owwo...",
                "....oo....",
                ".........."
            ]
        ),
        PixelSprite(
            key: "item.duckEgg",
            width: 10,
            palette: ["o": "4A5A6B", "w": "C9E4F5", "W": "F2FBFF", "s": "8FB4C9"],
            rows: [
                "..........",
                "...oooo...",
                "..owWWwo..",
                ".owWWWWwo.",
                ".oWWWWWWo.",
                ".oWWsWWWo.",
                ".oWWWWWWo.",
                "..owWWwo..",
                "...oooo...",
                ".........."
            ]
        ),
        PixelSprite(
            key: "item.milk",
            width: 10,
            palette: ["o": "5A6B7A", "w": "D9E4EA", "W": "FFFDF5", "y": "8FC3DD"],
            rows: [
                "....oo....",
                "...oyyo...",
                "...oWWo...",
                "..oWWWWo..",
                "..oWwWWo..",
                "..oWwWWo..",
                "..oWWWWo..",
                "..oWwWWo..",
                "..oooooo..",
                ".........."
            ]
        ),
        PixelSprite(
            key: "item.goatMilk",
            width: 10,
            palette: ["o": "5A4A3A", "w": "E8D9BE", "W": "FFF7E8", "y": "C9A227"],
            rows: [
                "....oo....",
                "...oyyo...",
                "...oWWo...",
                "..oWWWWo..",
                "..oWwWWo..",
                "..oWwWWo..",
                "..oWWWWo..",
                "..oWwWWo..",
                "..oooooo..",
                ".........."
            ]
        ),
        PixelSprite(
            key: "item.wool",
            width: 10,
            palette: ["o": "5A4A42", "w": "D9CBB4", "W": "FFF9EC", "s": "B8A88F"],
            rows: [
                "....oo....",
                "..ooWWoo..",
                ".oWWWWWWo.",
                ".oWWooWWo.",
                "oWWoWWoWWo",
                "oWWWWWWWWo",
                "oWWsoWWWWo",
                ".oWWWWWWo.",
                "..ooWWoo..",
                "....oo...."
            ]
        ),
        PixelSprite(
            key: "item.truffle",
            width: 10,
            palette: ["o": "4A3228", "b": "7A5540", "B": "A87A5E", "s": "5E4030"],
            rows: [
                "..........",
                "...oooo...",
                "..obbbbo..",
                ".obbBbbo..",
                ".obBBbbbo.",
                "oobbbbbsoo",
                "obbbbbbbso",
                ".obbbbbbo.",
                "..oooooo..",
                ".........."
            ]
        ),
        PixelSprite(
            key: "item.honey",
            width: 10,
            palette: ["o": "6B4A24", "y": "E8A93B", "Y": "F7D06B", "w": "FFF0B8"],
            rows: [
                "....oo....",
                "..oooooo..",
                "..oyyyyo..",
                ".oyYYyyo..",
                ".oyYwYyo..",
                ".oyYYyyo..",
                ".oyyyyyo..",
                ".oyYYyyo..",
                "..oooooo..",
                ".........."
            ]
        ),
        PixelSprite(
            key: "item.seed",
            width: 10,
            palette: [
                "o": "5A3A24", "y": "E8C15A", "Y": "F6E08A", "g": "5FA448", "G": "8DD06A"
            ],
            rows: [
                "oooooooooo",
                "oyYYYYYYyo",
                "oyooooooyo",
                "oyogggooyo",
                "oyogGgooyo",
                "oyogggooyo",
                "oyooooooyo",
                "oyYYYYYYyo",
                "oooooooooo",
                ".........."
            ]
        )
    ]

    // MARK: Fish

    private static let fish: [PixelSprite] = [
        PixelSprite(
            key: "fish.minnow",
            width: 12,
            palette: ["o": "3E4A55", "b": "8FA9B8", "B": "C9DCE6", "w": "FFFFFF", "k": "26303A"],
            rows: [
                "............",
                ".....oooo...",
                "..ooBBBBBBo.",
                ".oBBBBBBBBBo",
                "ooBBBBkBBBko",
                "oBBBBBBBBBBo",
                ".oBBBBBBBBo.",
                "..ooBBBBoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.bluegill",
            width: 12,
            palette: ["o": "2E4150", "b": "4F8AAE", "B": "8FC3DD", "y": "F2C744", "k": "22303A"],
            rows: [
                "............",
                ".....oooo...",
                "..ooBBBBBBo.",
                ".oBBBBBBBBBo",
                "ooBBBBkBBByo",
                "oBBBBBBByyyo",
                ".oBBBBBBByo.",
                "..ooBBBBoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.perch",
            width: 12,
            palette: ["o": "3E3A2A", "g": "6E8A4F", "G": "A8C46E", "y": "E8C15A", "k": "26241A"],
            rows: [
                "............",
                ".....oooo...",
                "..ooGGGGGGo.",
                ".oGGGGGGGGGo",
                "ooGGGGkGGGyo",
                "oGGyGGGGyyyo",
                ".oGGyGGGGyo.",
                "..ooGGGGGoo.",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.carp",
            width: 12,
            palette: ["o": "4A3A24", "b": "A87A4F", "B": "D3A478", "y": "E8C15A", "k": "2B2119"],
            rows: [
                "............",
                "....oooo....",
                "..ooBBBBBBo.",
                ".oBBBBBBBBBo",
                "ooBBBBkBBByo",
                "oBBBBBBByyyo",
                ".oBBBBBBByo.",
                "..ooBBBBoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.trout",
            width: 12,
            palette: ["o": "34424A", "b": "7FA8B8", "B": "C9E4EF", "p": "E8879F", "k": "223038"],
            rows: [
                "............",
                ".....oooo...",
                "..ooBBBBBBo.",
                ".oBBpBBpBBBo",
                "ooBBBBkBBpBo",
                "oBpBBBBBBBBo",
                ".oBBpBBBBBo.",
                "..ooBBBBoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.catfish",
            width: 12,
            palette: ["o": "2E2A32", "b": "5E5A6B", "B": "928FA3", "w": "D9D6E0", "k": "1D1A21"],
            rows: [
                "....w..w....",
                ".....oooo...",
                "..ooBBBBBBo.",
                ".oBBBBBBBBBo",
                "ooBBBBkBBBBo",
                "oBBBBBBBBBBw",
                ".oBBBBBBBBo.",
                "..ooBBBBoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.bass",
            width: 12,
            palette: ["o": "2E3A26", "g": "4F6B3A", "G": "7FA84F", "y": "E8C15A", "k": "1F281A"],
            rows: [
                "............",
                ".....oooo...",
                "..ooGGGGGGo.",
                ".oGGGGGGGGGo",
                "ooGGGGkGGGGo",
                "oGGyGGGGGyyo",
                ".oGGyGGGGyo.",
                "..ooGGGGGoo.",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.koi",
            width: 12,
            palette: ["o": "6B3A24", "r": "E8754A", "R": "FFB07A", "w": "FFF4E8", "k": "2B1B1B"],
            rows: [
                "............",
                ".....oooo...",
                "..ooRRRRRRo.",
                ".oRRwRRRwRRo",
                "ooRRRRkRRRRo",
                "oRwRRRRRRwRo",
                ".oRRwRRRRRo.",
                "..ooRRRRoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.eel",
            width: 14,
            palette: ["o": "2A2A38", "b": "4F4F6B", "B": "7A7A9E", "y": "E8C15A", "k": "1B1B26"],
            rows: [
                "..............",
                "...oooo.......",
                "..oBBBBooo....",
                ".oBBBBBBBBoo..",
                "oBBBBBkBBBBBBo",
                ".oBBBBBBBBBBo.",
                "..ooooBBBBoo..",
                "......oooo...."
            ]
        ),
        PixelSprite(
            key: "fish.rainbowTrout",
            width: 12,
            palette: ["o": "34424A", "b": "8FB4C9", "B": "DDF5FF", "r": "E8754A", "y": "F2C744", "k": "223038"],
            rows: [
                "............",
                ".....oooo...",
                "..ooBBBBBBo.",
                ".oBrBBrBBBBo",
                "ooByBBkBBrBo",
                "oBrBBBBBBBBo",
                ".oByBrBBBBo.",
                "..ooBBBBoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.moonfish",
            width: 12,
            palette: ["o": "30364A", "b": "8E9AC4", "B": "D9E0FF", "w": "FFFFFF", "k": "1E2233"],
            rows: [
                "............",
                ".....oooo...",
                "..ooBBBBBBo.",
                ".oBBwBBwBBBo",
                "ooBBBBkBBBBo",
                "oBBwBBBBwBBo",
                ".oBBBBBBBBo.",
                "..ooBBBBoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.goldenCarp",
            width: 12,
            palette: ["o": "6B4A12", "y": "E8BC55", "Y": "FFE08A", "w": "FFF6D8", "k": "3A2A10"],
            rows: [
                "............",
                ".....oooo...",
                "..ooYYYYYYo.",
                ".oYYYYYYYYYo",
                "ooYYYYkYYYyo",
                "oYYwYYYYYyyo",
                ".oYYYYYYYyo.",
                "..ooYYYYoo..",
                ".....oo....."
            ]
        ),
        PixelSprite(
            key: "fish.hollowSturgeon",
            width: 14,
            palette: ["o": "262E38", "b": "4F5E6B", "B": "7F93A3", "w": "C9DCE6", "k": "171D24"],
            rows: [
                "..............",
                "....oo........",
                "..ooBBoooo....",
                ".oBBBBBBBBoo..",
                "oBBwBBBkBBBBBo",
                "oBBBBBBBBBBBBo",
                ".oBBBBBBBBBBo.",
                "..ooBBBBBBoo..",
                "....oooooo...."
            ]
        )
    ]

    // MARK: Dishes

    private static let dishes: [PixelSprite] = [
        PixelSprite(
            key: "dish.omelette",
            width: 12,
            palette: ["o": "7A5A3A", "p": "D9E4EA", "y": "F2C744", "Y": "FFE08A", "r": "E8754A", "g": "6FA84F"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opYYYYYYpo.",
                ".opYYrYYYpo.",
                ".opYrrrYYpo.",
                ".opYYYYYYpo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.honeyToast",
            width: 12,
            palette: ["o": "6B4A24", "w": "D9A478", "W": "F2C99A", "y": "E8A93B", "Y": "FFD37A"],
            rows: [
                "............",
                "...oooooo...",
                "..oWWWWWWo..",
                ".oWwWWyWWWo.",
                ".oWwWyyyWWo.",
                ".oWwWyYyWWo.",
                ".oWwWWyWWWo.",
                "..oWWWWWWo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.berryParfait",
            width: 12,
            palette: ["o": "5A3A4A", "g": "A8DDF0", "w": "FFF4E8", "r": "E04458", "R": "FF6B7A"],
            rows: [
                "............",
                "..o......o..",
                "..oggggggo..",
                "..owwwwwwo..",
                "..orrrrrro..",
                "..owwwwwwo..",
                "..orRrrrro..",
                "..oggggggo..",
                "..oooooooo..",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.carrotCake",
            width: 12,
            palette: ["o": "6B4A24", "c": "F2C99A", "C": "FFF4E8", "r": "E8754A", "g": "6FA84F"],
            rows: [
                "............",
                "....gg......",
                "...oCCCo....",
                "..oCCCCCo...",
                ".oCrrrrrCo..",
                ".oCCCCCCCo..",
                ".oCrrrrrCo..",
                ".oCCCCCCCo..",
                "..ooooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.cornChowder",
            width: 12,
            palette: ["o": "6B5A3A", "p": "D9E4EA", "y": "E8C15A", "Y": "FFE08A", "g": "6FA84F"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opYYYYYYpo.",
                ".opYyYYyYpo.",
                ".opYYgYYYpo.",
                ".opYyYYyYpo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.pumpkinSoup",
            width: 12,
            palette: ["o": "6B3A24", "p": "D9E4EA", "O": "E87524", "Y": "F9A44A", "g": "4F7D3B"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opOOOOOOpo.",
                ".opOYYYYOpo.",
                ".opOYggYOpo.",
                ".opOYYYYOpo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.lavenderTea",
            width: 12,
            palette: ["o": "5A4A6B", "p": "D9E4EA", "v": "8E6BC4", "V": "B79BE0", "w": "FFF4E8"],
            rows: [
                "............",
                "....vv......",
                "...vVVv.....",
                "..oVVVVo....",
                "..oVVVVo....",
                "..oVVVVo....",
                "...oooo.....",
                "..opwwpo....",
                "...oooo.....",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.sunflowerSalad",
            width: 12,
            palette: ["o": "5A4A2A", "p": "D9E4EA", "g": "6FA84F", "G": "9BD06C", "y": "E8C15A", "r": "E8754A"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opgGGgGGpo.",
                ".opGyGgGrpo.",
                ".opGGgGGGpo.",
                ".opgGrGGgpo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.goatCheesePlate",
            width: 12,
            palette: ["o": "6B4A24", "p": "D9E4EA", "c": "F2E8D5", "C": "FFF8EA", "y": "E8C15A", "g": "6FA84F"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opCCCCCCpo.",
                ".opCccCcypo.",
                ".opyCccCCpo.",
                ".opCCgCCCpo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.duckCustard",
            width: 12,
            palette: ["o": "6B5A3A", "p": "D9E4EA", "y": "F2C744", "Y": "FFE08A", "r": "C95B4E"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opYYYYYYpo.",
                ".opYyYYyYpo.",
                ".opYYrrYYpo.",
                ".opYyYYyYpo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.trufflePasta",
            width: 12,
            palette: ["o": "5A3A2A", "p": "D9E4EA", "y": "E8C15A", "Y": "FFE08A", "b": "7A5540", "g": "6FA84F"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opYYYYYYpo.",
                ".opYybbYyYpo",
                ".opYbYYbYYpo",
                ".opYybbYyYpo",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.moonberryTart",
            width: 12,
            palette: ["o": "3A3450", "p": "D9E4EA", "b": "4E6FC4", "B": "8FB4FF", "w": "EAF2FF", "y": "E8C15A"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opBBBBBBpo.",
                ".opBbBwbBpo.",
                ".opBBbBbBpo.",
                ".opyBBBBypo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.moonlitCocoa",
            width: 12,
            palette: ["o": "4A3A4A", "p": "D9E4EA", "b": "4E6FC4", "B": "8FB4FF", "w": "EAF2FF"],
            rows: [
                "............",
                "....ww......",
                "...wBBw.....",
                "..oBBBBo....",
                "..oBwBBo....",
                "..oBBBBo....",
                "...oooo.....",
                "..opBBpo....",
                "...oooo.....",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.harvestStew",
            width: 12,
            palette: ["o": "6B3A24", "p": "D9E4EA", "O": "E87524", "y": "E8C15A", "g": "6FA84F", "b": "7A5540"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opOOOOOOpo.",
                ".opOyggOyppo",
                ".opOygbbOpo.",
                ".opOyggOyppo",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.goldenPancakes",
            width: 12,
            palette: ["o": "6B4A24", "p": "D9E4EA", "y": "E8C15A", "Y": "FFE08A", "w": "FFF4E8", "b": "B8892E"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opYYYYYYpo.",
                ".opyyyyyypo.",
                ".opYyYYyYpo.",
                ".opyyyyyypo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.anglersPie",
            width: 12,
            palette: ["o": "6B4A24", "p": "D9E4EA", "y": "E8C15A", "Y": "FFE08A", "b": "7FA8B8", "g": "6FA84F"],
            rows: [
                "............",
                "...oooooo...",
                "..oppppppo..",
                ".opYyYYyYpo.",
                ".opyYbYyYpo.",
                ".opYyYbYyppo",
                ".opYyYYyYpo.",
                "..oppppppo..",
                "...oooooo...",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.sturgeonFeast",
            width: 12,
            palette: ["o": "3A2E28", "p": "D9E4EA", "b": "7FA8B8", "B": "C9E4EF", "y": "E8C15A", "g": "6FA84F"],
            rows: [
                "............",
                "..oooooooo..",
                ".oppppppppo.",
                ".opBBBBBBpo.",
                ".opBbBBbBpo.",
                ".opBBBBBBpo.",
                ".opgyyyygpo.",
                ".oppppppppo.",
                "..oooooooo..",
                "............"
            ]
        ),
        PixelSprite(
            key: "dish.hollowFeast",
            width: 12,
            palette: ["o": "3A2E28", "p": "D9E4EA", "r": "E8754A", "y": "E8C15A", "g": "6FA84F", "v": "8E6BC4"],
            rows: [
                "............",
                "..oooooooo..",
                ".oppppppppo.",
                ".oprygvyrpo.",
                ".opygrvygpo.",
                ".opvgyrgyppo",
                ".opyrgvyrppo",
                ".oppppppppo.",
                "..oooooooo..",
                "............"
            ]
        )
    ]
}
