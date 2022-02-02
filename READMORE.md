> ***To do:*** Add explanatory notes to the future features/API calls etc. section, currently they stop before there. *(2022.02.02.)*

# project tag deckdater

Tool for determining when a MtG decklist was last up to date, so you know which sets have released since then and might have cards you want for it.

Uses Scryfall data.

> This page is a copy of the README *(file where I'm supposed to try to explain myself)* where I try to add explanations for a lay audience as I go. It is, even more than the normal README and this entire project, a work in progress.

## interface

*Frontend visible to the user.*

> This is about making a front page in HTML for people to interact with. It needs to be written once and doesn't change.

- Instructions (e.g. "I do not need your basic lands")
- `textarea` for inputting decklist
- Button to trigger dating process
- Empty div for __verdict__ output
- Empty div for __update__ output (once implemented)
- Empty div for "go again" button (once implemented)

> `textarea` is a big text entry field. `div`s are the default form of empty/fill-able box for a webpage to assemble itself out of.

## carpentry

*The part of the backend involving setup that makes tables.*

1. Fetch latest version of Scryfall's unique card art bulk-data json object.
> json is a format for storing large amounts of data, in this case data that looks a lot like the contents of a spreadsheet. "bulk-data" is the name Scryfall uses for their various "download our entire database" options. The one I'm using is cards with unique art only, which cuts out some reprints, but not all.
2. Unpack Scryfall json into a table in database for manipulation (henceforth __bulk__)
> "make that data I just said looks a lot like the contents of a spreadsheet *actually* look/act like we're used to thinking of spreadsheets"
3. `SELECT name, id, released_at, set INTO cards FROM bulk WHERE reprint = 'false' AND multiverse_ids IS NOT NULL`.
> This is SQL. The variable names are all [based on how Scryfall handles it](https://scryfall.com/docs/api/cards). This command looks at the __bulk__ table and makes a new, smaller table of only cards that aren't reprints and are on Gatherer, including only their names, release dates, sets, and ID information for Scryfall itself. (I'm not currently using the ID for anything, but it seemed like it might come in handy.)

Here, make a lighter-weight table of only salient information (from our perspective) about cards that aren't reprints and that exist in Gatherer (which prunes out tokens and the like); its name is __cards__. This should be all we need going forward.

***To do:*** Determine when to trigger `DROP TABLE bulk`.
> This would delete __bulk__ (the "literally everything Scryfall sent me" table) when relevant.

***To do:*** Automate updates to __cards__. Maybe check the number of known sets on Scryfall once a week, and rehydrate the *carpentry* when it changes?
> Hydration is spritzing a thing with new/updated data to liven it up a bit. (Do I know if the metaphor feels that literal for other people? No. Is it how I remember? Yes.) Although in our case, given deckdater overwrites/replaces its own data any time it updates __cards__, it's more of a tsunami kind of situation.

***To do:*** Streamline rehydration in general. In case of emergency the correct __cards__ table is the one with the greatest `MAX(released_at)` and the most entries; determine what tests that best enables.
> I'm worried about something going wrong during this table creation process, and my best bet for how to find it right now is "tell deckdater to trust the table with the newest cards in it". Dates in this format are larger quantities when they're more recent, because it's defining a 'date' by counting up from a fixed time in the past.

## dating

*Process involved in deckdater deckdating a deck.*

> This process only happens when a user triggers it by entering text into the front page and then hitting the button. It's almost all JavaScript (there's detours into SQL to talk to __cards__ effectively).

1. Get, sanitize and parse user input:
- Remove basic lands, if there are any
- Remove duplicate entries
- Remove chaff like '1x [cardname]' and recognizably null or bad-faith input
- Add special characters for `LIKE` searching 
> Sanitizing data gets rid of potentially malicious code and at least some non-useful content. In this case, I want to find the individual card names someone entered, ignore things that would throw off the results (like if they ignored me first and put in basic lands), and filter out anything that would never be a card, got submitted by accident, or is trying to get into __cards__ and screw me over somehow. I'd also like to modify the card names, once I've found them, to make them easier to search from the computer's perspective - since people don't always enter a card's "full" name and punctuation is tricky - but we'll see how that turns out in practice.
2. Produce a string of comma-separated user-entered search terms, __deck__
> The end result of (1) is a list of cards separated with commas, because that's what I can send back to __cards__ to look into.
3. Define const __max__ by doing `SELECT MAX(released_at) FROM cards WHERE name LIKE` with __deck__.
> "Go to __cards__, find each card named something that the user entered as part of their decklist, figure out which of those cards is the most recent, and call the release date of that most recent card __max__." 
4. Use __max__ and __deck__ in `SELECT name, released_at, set FROM cards WHERE date = ? HAVING name = ?`.
> The question marks are a product of moving between SQL and JavaScript. This asks __cards__ for the name, release date, and set of every card mentioned in the user's decklist that was released on the day the most recent card(s) they entered were released.
5. Bring the result of (4) in as __latest__.
> Stuff the answer to that query into a format that JavaScript can manipulate.
6. Define const __lastSet__ as `latest.latest[0].set` and const __lastDay__ as `latest.latest[0].released_at`.
> [0] in this context will be the *first* item in a list(/string/array). This wants to record what the set and release date named in the answer to "what's the set and release date of the most recent card(s)" actually *are*, in what will be a human-readable format.
7. Break the various `name`s out of __latest__ as their own array __news__.
> Make an array (a list of items made of random-from-the-computer's-perspective contents) listing the names of the recent cards we identified.
8. Produce __verdict__: 
- `if (news.length === 1) { let additions = "This deck's newest card is " + news[0]} else if (news.length === 2) { let additions = "The newest cards in this deck are " + news[0] + " and " + news[1]} else { let additions = "The newest cards in this deck are " + news.join(", ")}` (for grammar), then
> Check how many recent cards there actually are, and phrase the text surrounding their names differently depending on the answer. "news.join(", ")" puts together the items in news separated by a comma and a space.
- `let verdict = additions + ", first printed in " + lastSet + ". Your deck is up to date as of " + lastDay + "."`
> Take the "additions" text we just defined, add a message about the set and date involved, and call the whole thing __verdict__ so it's easier to carry around.
9. Put __verdict__ back into the document in its designated results div.
> This will put the contents of __verdict__ into one of those previously-empty boxes (divs) in the page the user sees. This is the first and only part of the dating process that changes something a person looking at the front page would be aware of.

## later

*Additional QOL improvements.*

### Listing sets since last update (API call)

Have existing value __max__, the most recent known update of the deck as entered.

Call Scryfall for the current list of sets as __allSets__.

~~~
function recency(date) { return date >= max; };

let newSets = allSets.filter(recency);
let updates = [];

for (i = 0; i < newSets.length; i++) {
 if (newSets.newSets[i].set_type === (core || expansion || draft_innovation || commander)) {
  let which = newSets.newSets[i].name;
  let what = newSets.newSets[i].code;
  let when = newSets.newSets[i].released_at;
  let jefferson = which + " (" + what + "), released " + when;
  updates.push(jefferson);
 }
};
if (updates.length === 0) {
 let update = "This deck is up to date!";
 return update;
} else if (updates.length === 1) {
 let update = "This deck was last updated prior to " + updates[0] + ".";
 return update;
} else if (updates.length === 2) {
 let update = "This deck has not been updated since before " + updates.[0] + ", and " + updates[1] + ", came out.";
 return update;
} else {
 let penultimate = updates.slice(0, (updates.length - 2));
 let update = "Since this deck was last updated, the following sets have been released: " penultimate.join("; ") + "and " + updates[(updates.length - 1)] + ".";
 return update;
}
~~~

Append __update__ to the results after the __verdict__.

### In case of unfamiliar cards (API call)

***Needs:*** A way to determine which card names in __deck__ that appear to be otherwise legit *didn't* find a match in __cards__.

- Assume for the time being that we have that information, as __strangers__.
- Search Scryfall API for those cards by name. (Remember: 10 searches per second.) 
- Results that are real cards (found on Scryfall, not a reprint, not a token, etc.) and weren't in __cards__ are now __friends__. (Because we've met them.)
- Check the `released_at` of our new __friends__. 
- If any is `>` existing __max__, STOP HERE and do a round of *carpentry* updates: __cards__ is missing a set. (Restart with the same __deck__ after this. May want a loading message to let the user know.)
- If all are `<=` existing __max__, assume Scryfall's more sophisticated fuzzy search caught user typos we couldn't. 
- Add __friends__ whose `released_at` date also `=` __max__ to the final __verdict__.

### Ability to date multiple decks (frontend)

*As of 22.02.02 you are being spared because I can't think of an archaeology (because dating like carbon dating) plus polyamory (because dating like multiple nerds dating) pun to put here.*

Package interface as a single component so that it can be duplicated. (Request was the ability to add multiple decks without refreshing; solution: multiple instances of the deckdater entry/output component in root.) Add a button after results generate asking if the user would like to date another deck; this prevents conflicting dating processes from happening simultaneously but means they don't have to reload. I think.

## notes 

#### on function and variable names 

- *Carpentry* (and related/resulting names; yes, that includes *jesus*) is the thing that makes tables.
- Within `for (i = 0; i < newSets.length; i++)`, __jefferson__ exists to ferry __what__ the user may have missed to __updates__. In other words, [it is a Hamilton joke](https://genius.com/Daveed-diggs-leslie-odom-jr-okieriete-onaodowan-and-original-broadway-cast-of-hamilton-whatd-i-miss-lyrics), my dudes and non-dudes.
- __strangers__ are just __friends__ who haven't shared their ~~secrets~~ set codes yet.

#### on homosexuality

This one's for Martin. 

If you're not Martin, you can still look at it, though. You just won't be Martin, which you would already have been doing anyway.
