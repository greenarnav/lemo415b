import CoreLocation

struct AreaCodeLookup {
    // Static method for looking up city by area code
    static func city(for areaCode: String) -> (city: String, state: String)? {
        // Look up area code in the location database
        let lookup = LocationLookup.shared
        if let (cityName, _) = lookup.city(for: areaCode) {
            return (city: cityName, state: "")
        }
        
        // Fallback for known area codes (hardcoded for now)
        switch areaCode {
        case "201":
            return (city: "Jersey City", state: "New Jersey")
        case "212":
            return (city: "Manhattan", state: "New York")
        case "213":
            return (city: "Los Angeles", state: "California")
        case "214":
            return (city: "Dallas", state: "Texas")
        case "215":
            return (city: "Philadelphia", state: "Pennsylvania")
        case "216":
            return (city: "Cleveland", state: "Ohio")
        case "217":
            return (city: "Springfield", state: "Illinois")
        case "224":
            return (city: "Chicago", state: "Illinois")
        case "225":
            return (city: "Baton Rouge", state: "Louisiana")
        case "234":
            return (city: "Akron", state: "Ohio")
        case "239":
            return (city: "Fort Myers", state: "Florida")
        case "240":
            return (city: "Rockville", state: "Maryland")
        case "248":
            return (city: "Detroit", state: "Michigan")
        case "251":
            return (city: "Mobile", state: "Alabama")
        case "252":
            return (city: "Greenville", state: "North Carolina")
        case "253":
            return (city: "Tacoma", state: "Washington")
        case "256":
            return (city: "Huntsville", state: "Alabama")
        case "260":
            return (city: "Fort Wayne", state: "Indiana")
        case "267":
            return (city: "Philadelphia", state: "Pennsylvania")
        case "269":
            return (city: "Kalamazoo", state: "Michigan")
        case "281":
            return (city: "Houston", state: "Texas")
        case "301":
            return (city: "Rockville", state: "Maryland")
        case "302":
            return (city: "Wilmington", state: "Delaware")
        case "303":
            return (city: "Denver", state: "Colorado")
        case "304":
            return (city: "Charleston", state: "West Virginia")
        case "305":
            return (city: "Miami", state: "Florida")
        case "307":
            return (city: "Cheyenne", state: "Wyoming")
        case "308":
            return (city: "Grand Island", state: "Nebraska")
        case "309":
            return (city: "Peoria", state: "Illinois")
        case "310":
            return (city: "Los Angeles", state: "California")
        case "312":
            return (city: "Chicago", state: "Illinois")
        case "313":
            return (city: "Detroit", state: "Michigan")
        case "314":
            return (city: "St. Louis", state: "Missouri")
        case "315":
            return (city: "Syracuse", state: "New York")
        case "316":
            return (city: "Wichita", state: "Kansas")
        case "317":
            return (city: "Indianapolis", state: "Indiana")
        case "318":
            return (city: "Shreveport", state: "Louisiana")
        case "319":
            return (city: "Cedar Rapids", state: "Iowa")
        case "320":
            return (city: "St. Cloud", state: "Minnesota")
        case "321":
            return (city: "Orlando", state: "Florida")
        case "323":
            return (city: "Los Angeles", state: "California")
        case "330":
            return (city: "Akron", state: "Ohio")
        case "334":
            return (city: "Montgomery", state: "Alabama")
        case "336":
            return (city: "Greensboro", state: "North Carolina")
        case "337":
            return (city: "Lafayette", state: "Louisiana")
        case "347":
            return (city: "New York", state: "New York")
        case "351":
            return (city: "Boston", state: "Massachusetts")
        case "352":
            return (city: "Gainesville", state: "Florida")
        case "360":
            return (city: "Vancouver", state: "Washington")
        case "361":
            return (city: "Corpus Christi", state: "Texas")
        case "385":
            return (city: "Salt Lake City", state: "Utah")
        case "386":
            return (city: "Daytona Beach", state: "Florida")
        case "401":
            return (city: "Providence", state: "Rhode Island")
        case "402":
            return (city: "Omaha", state: "Nebraska")
        case "404":
            return (city: "Atlanta", state: "Georgia")
        case "405":
            return (city: "Oklahoma City", state: "Oklahoma")
        case "406":
            return (city: "Billings", state: "Montana")
        case "407":
            return (city: "Orlando", state: "Florida")
        case "408":
            return (city: "San Jose", state: "California")
        case "409":
            return (city: "Beaumont", state: "Texas")
        case "410":
            return (city: "Baltimore", state: "Maryland")
        case "412":
            return (city: "Pittsburgh", state: "Pennsylvania")
        case "413":
            return (city: "Springfield", state: "Massachusetts")
        case "414":
            return (city: "Milwaukee", state: "Wisconsin")
        case "415":
            return (city: "San Francisco", state: "California")
        case "417":
            return (city: "Springfield", state: "Missouri")
        case "419":
            return (city: "Toledo", state: "Ohio")
        case "423":
            return (city: "Chattanooga", state: "Tennessee")
        case "424":
            return (city: "Los Angeles", state: "California")
        case "425":
            return (city: "Bellevue", state: "Washington")
        case "430":
            return (city: "Tyler", state: "Texas")
        case "432":
            return (city: "Midland", state: "Texas")
        case "434":
            return (city: "Charlottesville", state: "Virginia")
        case "435":
            return (city: "St. George", state: "Utah")
        case "440":
            return (city: "Cleveland", state: "Ohio")
        case "443":
            return (city: "Baltimore", state: "Maryland")
        case "480":
            return (city: "Tempe", state: "Arizona")
        case "484":
            return (city: "Allentown", state: "Pennsylvania")
        case "501":
            return (city: "Little Rock", state: "Arkansas")
        case "502":
            return (city: "Louisville", state: "Kentucky")
        case "503":
            return (city: "Portland", state: "Oregon")
        case "504":
            return (city: "New Orleans", state: "Louisiana")
        case "505":
            return (city: "Albuquerque", state: "New Mexico")
        case "507":
            return (city: "Rochester", state: "Minnesota")
        case "508":
            return (city: "Worcester", state: "Massachusetts")
        case "509":
            return (city: "Spokane", state: "Washington")
        case "510":
            return (city: "Oakland", state: "California")
        case "512":
            return (city: "Austin", state: "Texas")
        case "513":
            return (city: "Cincinnati", state: "Ohio")
        case "515":
            return (city: "Des Moines", state: "Iowa")
        case "516":
            return (city: "Long Island", state: "New York")
        case "517":
            return (city: "Lansing", state: "Michigan")
        case "518":
            return (city: "Albany", state: "New York")
        case "520":
            return (city: "Tucson", state: "Arizona")
        case "530":
            return (city: "Sacramento", state: "California")
        case "540":
            return (city: "Roanoke", state: "Virginia")
        case "541":
            return (city: "Eugene", state: "Oregon")
        case "551":
            return (city: "Jersey City", state: "New Jersey")
        case "559":
            return (city: "Fresno", state: "California")
        case "561":
            return (city: "West Palm Beach", state: "Florida")
        case "562":
            return (city: "Long Beach", state: "California")
        case "563":
            return (city: "Davenport", state: "Iowa")
        case "567":
            return (city: "Toledo", state: "Ohio")
        case "571":
            return (city: "Arlington", state: "Virginia")
        case "573":
            return (city: "Columbia", state: "Missouri")
        case "574":
            return (city: "South Bend", state: "Indiana")
        case "580":
            return (city: "Lawton", state: "Oklahoma")
        case "585":
            return (city: "Rochester", state: "New York")
        case "586":
            return (city: "Warren", state: "Michigan")
        case "601":
            return (city: "Jackson", state: "Mississippi")
        case "602":
            return (city: "Phoenix", state: "Arizona")
        case "603":
            return (city: "Manchester", state: "New Hampshire")
        case "605":
            return (city: "Sioux Falls", state: "South Dakota")
        case "606":
            return (city: "Ashland", state: "Kentucky")
        case "607":
            return (city: "Binghamton", state: "New York")
        case "608":
            return (city: "Madison", state: "Wisconsin")
        case "609":
            return (city: "Trenton", state: "New Jersey")
        case "610":
            return (city: "Reading", state: "Pennsylvania")
        case "612":
            return (city: "Minneapolis", state: "Minnesota")
        case "614":
            return (city: "Columbus", state: "Ohio")
        case "615":
            return (city: "Nashville", state: "Tennessee")
        case "616":
            return (city: "Grand Rapids", state: "Michigan")
        case "617":
            return (city: "Boston", state: "Massachusetts")
        case "618":
            return (city: "Belleville", state: "Illinois")
        case "619":
            return (city: "San Diego", state: "California")
        case "620":
            return (city: "Hutchinson", state: "Kansas")
        case "623":
            return (city: "Phoenix", state: "Arizona")
        case "626":
            return (city: "Pasadena", state: "California")
        case "628":
            return (city: "San Francisco", state: "California")
        case "629":
            return (city: "Nashville", state: "Tennessee")
        case "630":
            return (city: "Aurora", state: "Illinois")
        case "631":
            return (city: "Suffolk", state: "New York")
        case "636":
            return (city: "O'Fallon", state: "Missouri")
        case "641":
            return (city: "Mason City", state: "Iowa")
        case "646":
            return (city: "Manhattan", state: "New York")
        case "650":
            return (city: "San Mateo", state: "California")
        case "651":
            return (city: "St. Paul", state: "Minnesota")
        case "657":
            return (city: "Anaheim", state: "California")
        case "660":
            return (city: "Sedalia", state: "Missouri")
        case "661":
            return (city: "Bakersfield", state: "California")
        case "662":
            return (city: "Southaven", state: "Mississippi")
        case "667":
            return (city: "Baltimore", state: "Maryland")
        case "678":
            return (city: "Atlanta", state: "Georgia")
        case "681":
            return (city: "Charleston", state: "West Virginia")
        case "682":
            return (city: "Fort Worth", state: "Texas")
        case "701":
            return (city: "Fargo", state: "North Dakota")
        case "702":
            return (city: "Las Vegas", state: "Nevada")
        case "703":
            return (city: "Arlington", state: "Virginia")
        case "704":
            return (city: "Charlotte", state: "North Carolina")
        case "706":
            return (city: "Augusta", state: "Georgia")
        case "707":
            return (city: "Santa Rosa", state: "California")
        case "708":
            return (city: "Cicero", state: "Illinois")
        case "712":
            return (city: "Sioux City", state: "Iowa")
        case "713":
            return (city: "Houston", state: "Texas")
        case "714":
            return (city: "Anaheim", state: "California")
        case "715":
            return (city: "Eau Claire", state: "Wisconsin")
        case "716":
            return (city: "Buffalo", state: "New York")
        case "717":
            return (city: "Lancaster", state: "Pennsylvania")
        case "718":
            return (city: "Brooklyn", state: "New York")
        case "719":
            return (city: "Colorado Springs", state: "Colorado")
        case "720":
            return (city: "Denver", state: "Colorado")
        case "724":
            return (city: "New Castle", state: "Pennsylvania")
        case "727":
            return (city: "St. Petersburg", state: "Florida")
        case "731":
            return (city: "Jackson", state: "Tennessee")
        case "732":
            return (city: "Toms River", state: "New Jersey")
        case "734":
            return (city: "Ann Arbor", state: "Michigan")
        case "737":
            return (city: "Austin", state: "Texas")
        case "740":
            return (city: "Zanesville", state: "Ohio")
        case "754":
            return (city: "Fort Lauderdale", state: "Florida")
        case "757":
            return (city: "Virginia Beach", state: "Virginia")
        case "760":
            return (city: "Oceanside", state: "California")
        case "762":
            return (city: "Columbus", state: "Georgia")
        case "763":
            return (city: "Brooklyn Park", state: "Minnesota")
        case "765":
            return (city: "Muncie", state: "Indiana")
        case "770":
            return (city: "Atlanta", state: "Georgia")
        case "772":
            return (city: "Port St. Lucie", state: "Florida")
        case "773":
            return (city: "Chicago", state: "Illinois")
        case "774":
            return (city: "Worcester", state: "Massachusetts")
        case "775":
            return (city: "Reno", state: "Nevada")
        case "779":
            return (city: "Rockford", state: "Illinois")
        case "781":
            return (city: "Boston", state: "Massachusetts")
        case "785":
            return (city: "Topeka", state: "Kansas")
        case "786":
            return (city: "Miami", state: "Florida")
        case "801":
            return (city: "Salt Lake City", state: "Utah")
        case "802":
            return (city: "Burlington", state: "Vermont")
        case "803":
            return (city: "Columbia", state: "South Carolina")
        case "804":
            return (city: "Richmond", state: "Virginia")
        case "805":
            return (city: "Ventura", state: "California")
        case "806":
            return (city: "Lubbock", state: "Texas")
        case "808":
            return (city: "Honolulu", state: "Hawaii")
        case "810":
            return (city: "Flint", state: "Michigan")
        case "812":
            return (city: "Evansville", state: "Indiana")
        case "813":
            return (city: "Tampa", state: "Florida")
        case "814":
            return (city: "Erie", state: "Pennsylvania")
        case "815":
            return (city: "Rockford", state: "Illinois")
        case "816":
            return (city: "Kansas City", state: "Missouri")
        case "817":
            return (city: "Fort Worth", state: "Texas")
        case "818":
            return (city: "San Fernando", state: "California")
        case "828":
            return (city: "Asheville", state: "North Carolina")
        case "830":
            return (city: "New Braunfels", state: "Texas")
        case "831":
            return (city: "Salinas", state: "California")
        case "832":
            return (city: "Houston", state: "Texas")
        case "843":
            return (city: "Charleston", state: "South Carolina")
        case "845":
            return (city: "New York", state: "New York")
        case "847":
            return (city: "Waukegan", state: "Illinois")
        case "848":
            return (city: "Toms River", state: "New Jersey")
        case "850":
            return (city: "Tallahassee", state: "Florida")
        case "854":
            return (city: "Charleston", state: "South Carolina")
        case "856":
            return (city: "Camden", state: "New Jersey")
        case "857":
            return (city: "Boston", state: "Massachusetts")
        case "858":
            return (city: "San Diego", state: "California")
        case "859":
            return (city: "Lexington", state: "Kentucky")
        case "860":
            return (city: "Hartford", state: "Connecticut")
        case "862":
            return (city: "Newark", state: "New Jersey")
        case "863":
            return (city: "Lakeland", state: "Florida")
        case "864":
            return (city: "Greenville", state: "South Carolina")
        case "865":
            return (city: "Knoxville", state: "Tennessee")
        case "870":
            return (city: "Jonesboro", state: "Arkansas")
        case "878":
            return (city: "Pittsburgh", state: "Pennsylvania")
        case "901":
            return (city: "Memphis", state: "Tennessee")
        case "903":
            return (city: "Tyler", state: "Texas")
        case "904":
            return (city: "Jacksonville", state: "Florida")
        case "906":
            return (city: "Marquette", state: "Michigan")
        case "907":
            return (city: "Anchorage", state: "Alaska")
        case "908":
            return (city: "Elizabeth", state: "New Jersey")
        case "909":
            return (city: "San Bernardino", state: "California")
        case "910":
            return (city: "Fayetteville", state: "North Carolina")
        case "912":
            return (city: "Savannah", state: "Georgia")
        case "913":
            return (city: "Kansas City", state: "Kansas")
        case "914":
            return (city: "Westchester", state: "New York")
        case "915":
            return (city: "El Paso", state: "Texas")
        case "916":
            return (city: "Sacramento", state: "California")
        case "917":
            return (city: "New York", state: "New York")
        case "918":
            return (city: "Tulsa", state: "Oklahoma")
        case "919":
            return (city: "Raleigh", state: "North Carolina")
        case "920":
            return (city: "Green Bay", state: "Wisconsin")
        case "925":
            return (city: "Concord", state: "California")
        case "928":
            return (city: "Yuma", state: "Arizona")
        case "929":
            return (city: "Brooklyn", state: "New York")
        case "936":
            return (city: "Huntsville", state: "Texas")
        case "937":
            return (city: "Dayton", state: "Ohio")
        case "938":
            return (city: "Huntsville", state: "Alabama")
        case "940":
            return (city: "Denton", state: "Texas")
        case "941":
            return (city: "Sarasota", state: "Florida")
        case "947":
            return (city: "Troy", state: "Michigan")
        case "949":
            return (city: "Irvine", state: "California")
        case "951":
            return (city: "Riverside", state: "California")
        case "952":
            return (city: "Bloomington", state: "Minnesota")
        case "954":
            return (city: "Fort Lauderdale", state: "Florida")
        case "956":
            return (city: "Laredo", state: "Texas")
        case "959":
            return (city: "Hartford", state: "Connecticut")
        case "970":
            return (city: "Fort Collins", state: "Colorado")
        case "971":
            return (city: "Portland", state: "Oregon")
        case "972":
            return (city: "Dallas", state: "Texas")
        case "973":
            return (city: "Newark", state: "New Jersey")
        case "978":
            return (city: "Lowell", state: "Massachusetts")
        case "979":
            return (city: "College Station", state: "Texas")
        case "980":
            return (city: "Charlotte", state: "North Carolina")
        case "984":
            return (city: "Raleigh", state: "North Carolina")
        case "985":
            return (city: "Houma", state: "Louisiana")
        case "989":
            return (city: "Saginaw", state: "Michigan")
        default:
            return nil
        }
    }
}
