# project tag deckdater

Tool for determining when a MtG decklist was last up to date, so you know which sets have released since then and might have cards you want for it.

Uses Scryfall data.

## carpentry

*The part of the backend involving setup that makes tables.*

1. Fetch latest version of Scryfall's unique card art bulk-data json object.
2. Unpack Scryfall json into a table in database for manipulation (henceforth __bulk__)
3. 

## interface

*Frontend visible to the user.*

#### request TBA

Package interface as a single component so that it can be duplicated. (Request was the ability to add multiple decks without refreshing; solution: multiple instances of the deckdater entry/output component in root.)

## dating

*Process involved in deckdater deckdating a deck.*

1. Sanitize and parse user input:
- Remove basic lands, if there are any
- Remove duplicate entries
- Remove chaff like '1x [cardname]' and recognizably null or bad-faith input
- Add special characters for `LIKE` searching 
2. Produce a string of comma-separated user-entered search terms, __deck__
3. Define const __max__ by doing `SELECT MAX(released_at) FROM cards WHERE name LIKE` with __deck__.
4. Use __max__ and __deck__ in `SELECT name, released_at, set FROM cards WHERE date = ? HAVING name = ?`.
5. 

### add API calls

*Additional QOL improvements involving Scryfall API calls.*

#### Listing sets since last update 

Have existing value __max__, the most recent known update of the deck as entered.

Call Scryfall for the current list of sets as __allSets__.

`function recency(date) { return date >= max; };`
`let newSets = allSets.filter(recency);`
`let updates = [];`
`for (i = 0; i < newSets.length; i++) {`
`if (newSets.newSets[i].set_type === (core || expansion || draft_innovation || commander)) {`
` let which = newSets.newSets[i].name;`
` let what = newSets.newSets[i].code;`
` let when = newSets.newSets[i].released_at;`
` let jefferson = which + " (" + what + "), released " + when;`
` updates.push(jefferson);`
` }` 
`};`

`if (updates.length === 0) {`
` let update = "This deck is up to date!";`
` return update;`
`} else if (updates.length === 1) {`
` let update = "This deck was last updated prior to " + updates[0] + ".";`
` return update;`
`} else if (updates.length === 2) {`
` let update = "This deck has not been updated since before " + updates.[0] + ", and " + updates[1] + ", came out.";`
` return update;`
`} else {`
` let penultimate = updates.slice(0, (updates.length - 2));`
` let update = "Since this deck was last updated, the following sets have been released: " penultimate.join("; ") + "and " + updates[(updates.length - 1)] + ".";`
` return update;`
`}`

Append __update__ to the results.

#### In case of unfamiliar cards 