-- The game in two languages.
--
-- **The English string is the key.** There is no table of symbolic ids anywhere:
-- a line of copy stays written out, in English, in the module it belongs to --
-- the upgrade's own row in src/upgrades.lua, the tool's name in src/tools.lua,
-- the prompt at the top of the screen that says it -- and this file maps that
-- English to Spanish. Every place the game *draws* a string puts it through
-- `I18n.t` on the way to the page.
--
-- That is a deliberate choice and it buys three things worth having. The
-- catalogue keeps its shape: adding an upgrade is still one row in
-- `Upgrades.list` and nothing else, which is the rule the whole extending
-- section of CLAUDE.md is written along, and it would not survive a scheme where
-- a new line meant editing an id table twice as well. A string with no
-- translation falls through to the English rather than to a key, so an
-- un-translated line reads as English copy instead of as `hud.kills.2`. And the
-- source stays readable -- the levels of the pencil line say what they do where
-- they are written, which is most of what makes that file possible to balance.
--
-- What it costs is that two things meaning different things must not be written
-- the same way in English, since they would share a translation. Nothing in the
-- game does today; if it ever does, the fix is to reword one of them, which is
-- usually an improvement anyway.
--
-- **Translation happens at the draw, never at load.** Nothing here is baked into
-- a data table when the module is required, because the language can be changed
-- from the title screen and from the settings page and the catalogue is the same
-- table for every run the program plays. So `Upgrades.list` holds English for
-- ever and src/levelup.lua, src/library.lua and the rest ask for the Spanish
-- each time they draw it.
--
-- Two things about how the Spanish is *set*, both forced by the 3x5 face
-- (src/font.lua):
--
-- **No acute accents.** A capital in that face fills all five rows and there is
-- nowhere above one to put a mark, so it is ORBITA and MUSICA. Leaving the
-- accent off a capital is ordinary in display lettering; drawing a mark into the
-- letter would not be.
--
-- **N-tilde, and the inverted marks, are drawn.** N-tilde is a letter of the
-- alphabet rather than an accented N -- a word with N in its place is misspelt --
-- and the inverted question and exclamation marks open a sentence in Spanish, so
-- all three are glyphs in the face. They are two bytes each in UTF-8, which is
-- why src/font.lua counts letters rather than bytes.
--
-- **No commas.** The face has no comma glyph (it draws as a blank), so the
-- Spanish is written without them -- the same rule a character blurb is already
-- held to.
--
-- **What is deliberately not translated.** Two things, and they are the same
-- thing: a name is not a sentence.
--
-- The **title** on the front of the book is the game's name. SURVIVE SCHOOL
-- reads as SURVIVE SCHOOL in Spanish the way any title does -- it is what the
-- thing is called, not a line of copy about it -- so both of its words stay out
-- of the table below and the title screen draws its own constants. Which is also
-- what keeps that screen's opening honest: the intro writes the title on one
-- letter at a time over a clock struck off its length, and a title that changed
-- length would be an opening that ran at two speeds.
--
-- The **languages' own names** are the other, for the reason given at
-- `I18n.langs`: someone looking for Spanish is looking for the word ESPANOL.
--
-- Which language is picked is saved with the volumes in src/options.lua.

local I18n = {}

-- A language's own name for itself, since that is the one thing on a language
-- selector that should not be translated: someone looking for Spanish is looking
-- for the word ESPANOL, not for the word SPANISH.
--
-- `code` is the two letters the title screen's corner button wears. It is the
-- whole of that button, so it has to be a pair of letters that reads as a
-- language at a glance and fits an eleven pixel box.
I18n.langs = {
    { key = "en", code = "EN", name = "ENGLISH" },
    { key = "es", code = "ES", name = "ESPAÑOL" },
}

I18n.lang = "en"

-- Every string the player can read, in the order the game shows them: the title
-- screen, then the screens off it, then the run, then the catalogue. English on
-- the left because English is the key.
--
-- Where a string carries a number it carries it as a format specifier, so the
-- number can move inside the sentence -- which it has to, since a Spanish
-- sentence does not always put it where an English one does.
local ES = {
    --- the title screen -------------------------------------------------------

    -- The title itself is not in here, and that is deliberate: see **what is
    -- deliberately not translated** below.
    ["START?"] = "¿EMPEZAR?",
    ["YES"] = "SI",
    ["NO"] = "NO",
    -- The third box, and only there for a run that was walked out of and is
    -- still standing (src/menu.lua).
    ["CONTINUE"] = "CONTINUAR",
    ["SCRIBBLE IN A BOX"] = "GARABATEA UNA CASILLA",
    ["LIFT TO CONFIRM"] = "LEVANTA PARA CONFIRMAR",
    ["RELEASE TO CONFIRM"] = "SUELTA PARA CONFIRMAR",
    -- The keys stay Y and N in the code, but S is accepted alongside Y so the
    -- line can name the letter a Spanish speaker would reach for.
    ["OR PRESS Y OR N"] = "O PULSA S O N",
    -- The same line for a title screen that has the third box on it. Two strings
    -- rather than one with a letter appended, because the Spanish joins its last
    -- two with O rather than a comma and that is a whole sentence away from a
    -- list with a letter stuck on the end.
    ["OR PRESS Y N OR C"] = "O PULSA S N O C",

    --- settings ---------------------------------------------------------------

    ["SETTINGS"] = "AJUSTES",
    -- MUSIC is down in the subjects block: the lesson and the volume are the same
    -- word for the same thing in both languages, which is a collision that costs
    -- nothing and needs one entry rather than two.
    ["SOUND"] = "SONIDO",
    ["LANGUAGE"] = "IDIOMA",
    -- DEV, and out at launch with the row that reads them (src/dev.lua). ALL and
    -- NONE are the damage row's own words, down in this block already.
    ["UNLOCKS"] = "DESBLOQUEOS",
    ["EARNED"] = "GANADO",
    ["DRAG A BAR TO SET IT"] = "ARRASTRA UNA BARRA",
    ["DRAG A BAR OR USE THE ARROWS"] = "ARRASTRA O USA LAS FLECHAS",
    -- Whether the game opens a board for something it has just handed you. The
    -- row is worded as what it is about and the two words as what happens, in
    -- both languages: PREGUNTAR is the widest word either stepped row can hold
    -- and is what the arrows on both of them are struck off.
    -- Which way up the page is held. The two locks are what the page *is* rather
    -- than what it does, so they agree with PANTALLA and stay short: ANCHA and
    -- ALTA are both well inside PREGUNTAR, which is what the arrows on every
    -- stepped row are struck off, so this row moves nothing. AUTO has no line of
    -- its own because it is already the Spanish word, and a key with no entry
    -- comes back out of I18n.t unchanged.
    ["SCREEN"] = "PANTALLA",
    ["WIDE"] = "ANCHA",
    ["TALL"] = "ALTA",
    -- Which bottom corner the thumb stick is in, which with the row above it is
    -- one of the two here a phone needs and a desktop never uses.
    ["STICK"] = "PALANCA",
    ["LEFT"] = "IZQUIERDA",
    ["RIGHT"] = "DERECHA",
    -- How much of a hit the page says out loud. GRANDES rather than SOLO
    -- GRANDES: the row above it is what the words are about, and the shorter
    -- word is what keeps the block inside a phone held upright.
    ["DAMAGE NUMBERS"] = "NUMEROS DE DAÑO",
    ["ALL"] = "TODOS",
    ["BIG ONLY"] = "GRANDES",
    ["NONE"] = "NINGUNO",
    ["NEW DRAWINGS"] = "DIBUJOS NUEVOS",
    ["ASK"] = "PREGUNTAR",
    ["SKIP"] = "OMITIR",

    --- the timetable ----------------------------------------------------------

    ["TODAYS LESSON"] = "CLASE DE HOY",
    ["GO!"] = "¡VAMOS!",
    -- The board is where the hero is drawn, so the button says what pressing it
    -- gets you rather than what it is called.
    ["CUSTOM"] = "DIBUJAR",
    ["LIBRARY"] = "BIBLIOTECA",
    -- The two parts of the book behind the tabs above the library, and the
    -- headings of the pages themselves: the canteen, where the purse is read,
    -- and the homework page, which is not written yet.
    ["HOMEWORK"] = "DEBERES",
    ["CANTEEN"] = "CANTINA",
    ["HERO"] = "HEROE",
    ["TOOL"] = "UTIL",
    ["BEST"] = "MEJOR",
    ["KILLED"] = "BAJAS",
    -- The label, not the grade: a mark is a letter and a letter needs no
    -- translating (src/mark.lua), but the word for what it is does.
    ["MARK"] = "NOTA",
    -- Which class the run was sat as, on both end cards (src/course.lua). The
    -- Spanish is the noun where the English is the verb, and that is the natural
    -- reading in each. The register's own course needs no line: it rides along the
    -- BEST row on the timetable rather than labelling one, so what it wants there
    -- is the course's name and nothing else.
    ["SAT AT %s"] = "CURSO %s",
    -- The rungs of the ladder itself. They are the names of real Spanish
    -- qualifications rather than translations of the English ones -- INSTITUTO is
    -- the building and GRADO is the degree -- because what the column is naming is
    -- a thing a reader has actually sat. MASTER is the same word without its
    -- accent and loses the English plural, which is the whole of that line.
    ["HIGH SCHOOL"] = "INSTITUTO",
    ["BACHELOR"] = "GRADO",
    ["MASTERS"] = "MASTER",
    ["PHD"] = "DOCTORADO",

    --- the library ------------------------------------------------------------

    ["TOOLS"] = "UTILES",
    ["WEAPONS"] = "ARMAS",
    ["PASSIVES"] = "PASIVAS",
    ["TAP A NAME TO READ IT"] = "TOCA UN NOMBRE PARA LEERLO",
    ["CLICK A NAME OR USE THE ARROWS"] = "PULSA UN NOMBRE O USA LAS FLECHAS",

    -- The toggle in the bottom left corner of the library, and what the block
    -- under the shelf says while it is up with nothing to write out yet. The word
    -- itself is the longest thing in that corner in either language -- eleven
    -- letters in Spanish against ten in English -- and it is what the clearance
    -- off the left arrow is measured against (`lay.evoX` in src/library.lua).
    ["EVOLUTIONS"] = "EVOLUCIONES",
    ["PICK TWO TOOLS"] = "ELIGE DOS UTILES",
    ["NOTHING COMES OF THESE TWO"] = "DE ESTOS DOS NO SALE NADA",
    ["TAP TWO TOOLS TO PAIR THEM"] = "TOCA DOS UTILES PARA UNIRLOS",
    ["CLICK TWO TOOLS TO PAIR THEM"] = "PULSA DOS UTILES PARA UNIRLOS",

    -- A line the book has not opened yet, and the four things one can ask for
    -- (src/collection.lua). The demand is written as an order in both languages,
    -- since that is what it is: the register is being told what to come back with.
    --
    -- The two counts of pages come in three forms each -- one, some, all -- rather
    -- than in one with a number in it, because APRUEBA 1 CLASES is a sentence
    -- written by a machine and APRUEBA TODAS LAS CLASES is the book finished. Both
    -- languages need all three and neither needs a fourth.
    ["NOT IN THE BOOK YET"] = "AUN NO ESTA EN EL LIBRO",
    ["LAST %s IN ONE RUN"] = "AGUANTA %s DE UN TIRON",
    ["%d KILLS ON ONE PAGE"] = "%d BAJAS EN UNA PAGINA",
    ["SIT A LESSON TO THE END"] = "AGUANTA UNA CLASE ENTERA",
    ["SIT %d LESSONS TO THE END"] = "AGUANTA %d CLASES ENTERAS",
    ["SIT EVERY LESSON TO THE END"] = "AGUANTA TODAS LAS CLASES ENTERAS",
    ["BEAT A LESSON"] = "APRUEBA UNA CLASE",
    ["BEAT %d LESSONS"] = "APRUEBA %d CLASES",
    ["BEAT EVERY LESSON"] = "APRUEBA TODAS LAS CLASES",
    -- And the fusions, which are not missing from the book so much as unmade. SE
    -- HACE CON rather than HECHO DE: what the head is describing is a thing you do
    -- to two lines rather than a property of a third.
    ["MADE OF %s AND %s"] = "SE HACE CON %s Y %s",
    ["OPEN %s FIRST"] = "ABRE %s PRIMERO",
    -- The lesson tools, which are not missing from the book so much as tied to one
    -- page of it. The second line says ALLI rather than the lesson's name again,
    -- exactly as the English does -- and without its accent, like every other word
    -- in this file.
    ["ONLY IN %s"] = "SOLO EN %s",
    ["SURVIVE %d MINUTES THERE"] = "SOBREVIVE %d MINUTOS ALLI",
    -- And a page the book does not open at yet, which is the lesson tool's pair
    -- read from the other end and says so by borrowing its second line whole
    -- (src/collection.lua). DESPUES DE rather than TRAS, which is shorter and
    -- reads as a preposition in a timetable rather than as one in a sentence.
    ["ONLY AFTER %s"] = "SOLO DESPUES DE %s",
    -- And the weapons the three bought heroes carry, which are tied to a hero the
    -- way a tool is tied to a page (src/characters.lua). Two demands for one line:
    -- the hero has not been paid for, or he has and has not lasted yet.
    ["ONLY FOR %s"] = "SOLO PARA %s",
    ["BUY THAT HERO IN THE CANTEEN"] = "COMPRA ESE HEROE EN LA CANTINA",
    ["SURVIVE %d MINUTES AS THAT HERO"] = "SOBREVIVE %d MINUTOS CON ESE HEROE",

    --- pages that open onto nothing ------------------------------------------

    -- Nothing draws this any more -- the homework page grew a list and moved out
    -- into src/homework.lua, the way the canteen did before it -- and it is kept
    -- because it is what src/blank.lua says, and the next tab that opens onto
    -- nothing is that module with a heading.
    ["NOTHING HERE YET"] = "AQUI NO HAY NADA TODAVIA",

    --- the homework page -----------------------------------------------------

    -- The heading, and then the four sections and the handful of words the
    -- challenges are written in (src/challenges.lua). Most of the page needs no
    -- line of its own: a course's name, a tool's name, TOOLS, WEAPONS, PASSIVES
    -- and BEAT EVERY LESSON are all already up there, being the same words about
    -- the same things.
    ["HOMEWORK"] = "DEBERES",

    -- The four sections. BESTIARIO and COLECCION are the words a book would use;
    -- TERM is CURSO, which is the school year rather than the class -- the same
    -- word the timetable already spends on a rung of the ladder, and the one place
    -- in this file where that double meaning is wanted rather than tolerated,
    -- since the section is about lasting a year and beating one.
    ["BESTIARY"] = "BESTIARIO",
    ["TERM"] = "CURSO",
    ["COLLECTION"] = "COLECCION",

    -- The horde, one name per row of src/enemy.lua. They are the words the game
    -- has always called these things in English and had never had to say out loud
    -- until there was a page that named them.
    --
    -- BORRON is a blot of ink and GOTA is the drop that falls off one, which is
    -- the pair the monster and its three children are. MUECA is the pulled face
    -- rather than the smile -- what the grin is is a shape, not a mood.
    ["BLOB"] = "MANCHA",
    ["BAT"] = "MURCIELAGO",
    ["SKULL"] = "CALAVERA",
    ["WAD"] = "BOLA",
    ["BLOT"] = "BORRON",
    ["DROP"] = "GOTA",
    ["BULB"] = "BOMBILLA",
    ["GRIN"] = "MUECA",
    ["EYE"] = "OJO",
    ["RED EYE"] = "OJO ROJO",

    -- And the rest of the rows. HORAS rather than TIEMPO for the clock, because
    -- what the row is counting is hours at the book rather than a moment in one.
    ["BOSSES"] = "JEFES",
    ["TIME PLAYED"] = "HORAS JUGADAS",
    ["DRAWINGS"] = "DIBUJOS",

    -- The demands, written as orders in both languages for the collection's
    -- reason: the register is being told what to come back with. DE ELLOS carries
    -- the row's own name down from the column beside it, exactly as the English
    -- OF THEM does -- which is what lets one entry serve every monster in the
    -- bestiary instead of ten plurals.
    ["KILL %d OF THEM"] = "MATA %d DE ELLOS",
    -- DERROTA and not APRUEBA, which is the verb the book spends on a lesson: you
    -- pass a class and you beat a boss, and English happens to use one word for
    -- both. Spanish does not have to.
    ["BEAT %d OF THEM"] = "DERROTA %d DE ELLOS",
    ["PLAY %s"] = "JUEGA %s",
    ["OPEN EVERY ONE"] = "ABRELOS TODOS",
    ["DRAW EVERY ONE YOURSELF"] = "DIBUJALOS TODOS TU",

    --- the canteen, and the three things it sells ----------------------------

    -- What the purse is short of rather than what the page is: there is a figure
    -- on this one, and this is the line saying that is all there is. Nothing draws
    -- it any more -- the counter has three rows on it now -- and it is kept because
    -- the next page that opens onto nothing will want it.
    ["NOTHING TO BUY YET"] = "AUN NO HAY NADA QUE COMPRAR",
    ["SCRIBBLE A BOX TO BUY"] = "GARABATEA UNA CASILLA PARA COMPRAR",
    ["SCRIBBLE A BOX OR PRESS 1 2 3 4"] = "GARABATEA O PULSA 1 2 3 4",
    ["SCRIBBLE A BOX OR PRESS 1 2 3"] = "GARABATEA O PULSA 1 2 3",
    ["SCRIBBLE A BOX OR PRESS 1"] = "GARABATEA O PULSA 1",
    ["NOTHING LEFT TO BUY"] = "NO QUEDA NADA QUE COMPRAR",
    ["COME BACK WITH MORE COINS"] = "VUELVE CON MAS MONEDAS",
    ["EVERY LEVEL IS ONE USE A RUN"] = "CADA NIVEL ES UN USO POR PARTIDA",
    -- The counter's sections and the note under each of them, which is the one
    -- line on the page that says what a level of the thing you are looking at *is*.
    -- HEROES is the same word in both languages without its accent, so it has no
    -- line of its own -- an untranslated key falls through to the English.
    ["PERKS"] = "VENTAJAS",
    ["A HERO IS YOURS FOR GOOD"] = "UN HEROE ES TUYO PARA SIEMPRE",
    -- And the course ladder's section and its one row (src/course.lua): CURSOS for
    -- the section because a section is a name, CURSO for the row because a row is
    -- the thing itself. COURSE does double duty -- it is also the label on the
    -- timetable's own selector, which is the same word about the same thing, so
    -- one line does for both. The names of the four courses are up in the
    -- timetable block, where they are actually read.
    ["COURSES"] = "CURSOS",
    ["COURSE"] = "CURSO",
    ["EVERY LEVEL IS A HARDER BOOK"] = "CADA NIVEL ES UN LIBRO MAS DURO",
    ["HARDER BOOK, MORE COINS"] = "MAS DURO, MAS MONEDAS",
    -- And the last section, which sells nothing: the way back off the other three
    -- (src/refund.lua). DEVOLVER for the row because it is what pressing it does
    -- and REEMBOLSO for the section because a section is a name rather than an
    -- order -- the same split PERKS, CURSOS and REROLL are already on.
    ["REFUND"] = "REEMBOLSO",
    ["REFUND ALL"] = "DEVOLVER TODO",
    ["EVERY PERK HERO AND COURSE"] = "VENTAJAS HEROES Y CURSOS",
    ["YOU GET EVERY COIN BACK"] = "RECUPERAS TODAS LAS MONEDAS",
    ["SCRIBBLE A BOX TO REFUND"] = "GARABATEA UNA CASILLA PARA DEVOLVER",
    ["NOTHING TO REFUND"] = "NO HAY NADA QUE DEVOLVER",
    -- The four of them (src/perks.lua). SKIP is already up in the settings block,
    -- where it is the word for not being asked to draw something -- the same verb
    -- about the same kind of thing, so one entry does for both.
    ["REROLL"] = "REPETIR",
    ["EXPEL"] = "EXPULSAR",
    -- RECUPERAR rather than REPETIR, which the reroll already has: the Spanish for
    -- a retake exam is a recovery, and it is the same verb a page uses for getting
    -- health back -- which is exactly the two things this row is.
    ["RETAKE"] = "RECUPERAR",
    ["THREE NEW CARDS"] = "TRES CARTAS NUEVAS",
    ["SELL THE LEVEL BACK"] = "VENDE EL NIVEL",
    ["ONE LINE OUT OF THE RUN"] = "UNA LINEA FUERA DE LA PARTIDA",
    ["BACK UP ON HALF HEALTH"] = "VUELVES CON MEDIA VIDA",
    -- What the draft says when EXPEL is armed and the boxes have stopped meaning
    -- yes. THROW OUT rather than EXPEL again: the button is named and this is the
    -- sentence about what it is doing, and a line that repeated the word on the
    -- button would be telling you what you just pressed.
    ["SCRIBBLE THE LINE TO THROW OUT"] = "GARABATEA LA LINEA QUE SE VA",

    --- the drawing board -----------------------------------------------------

    ["DRAW YOUR"] = "DIBUJA TU",
    ["DRAW SOMETHING FIRST"] = "DIBUJA ALGO PRIMERO",
    ["OR PRESS ENTER"] = "O PULSA ENTER",
    ["OK!"] = "¡OK!",
    ["RESET"] = "BORRAR",
    ["SCRIBBLE OK! TO KEEP IT"] = "GARABATEA ¡OK! PARA GUARDARLO",
    ["SCRIBBLE OK! TO KEEP HIM"] = "GARABATEA ¡OK! PARA GUARDARLO",

    -- The boards, which are the things the player draws. HERO is already up in
    -- the timetable block and SHOT, SWORD, ROCKET, COOL S, BOMB and SKATE are
    -- already the names of the lines that hand them to you -- the same word for
    -- the same thing, so one entry does for both places it is read.
    ["SWORD"] = "ESPADA",
    ["SHOT"] = "BALA",
    ["STAR"] = "ESTRELLA",
    ["SUN FACE"] = "CARA DEL SOL",
    -- The one board whose line is called something else: the line is the STORM
    -- and what you draw on it is the bolt, since the cloud is not yours to draw.
    ["LIGHTNING"] = "RAYO",
    -- The other board whose line is called something else, and for the opposite
    -- reason: the line is every bird there is and the board is one of them.
    ["M BIRD"] = "PAJARO M",

    --- the characters --------------------------------------------------------

    -- The names are coined rather than descriptive in English -- four heroes on
    -- one shape -- and Spanish has no ending that does the same job for all four,
    -- so each is translated as what it is instead of as what it rhymes with.
    ["SHOOTMAN"] = "TIRADOR",
    ["SWORDSMAN"] = "ESPADACHIN",
    ["STARMAN"] = "ASTRO",
    ["SKATEMAN"] = "PATINADOR",
    ["SHOOTS WHAT IS NEAREST"] = "DISPARA AL MAS CERCANO",
    ["DOUBLE DAMAGE UP CLOSE"] = "DOBLE DAÑO DE CERCA",
    ["A STAR ORBITS HIM"] = "UNA ESTRELLA LE ORBITA",
    ["CUTS WHAT FOLLOWS HIM"] = "CORTA A QUIEN LE SIGUE",

    --- the subjects ----------------------------------------------------------

    ["SCIENCE"] = "BIOLOGIA",
    -- The paired-rule page. It was called LANGUAGE, which is the same English
    -- word the settings page needs for the language selector and a different
    -- Spanish one (LENGUA against IDIOMA) -- the one collision the
    -- English-as-key scheme actually hit here, and reworded rather than worked
    -- around. GRAMMAR is a better fit for the paper anyway: paired rules are
    -- handwriting lines.
    ["GRAMMAR"] = "GRAMATICA",
    ["P.E."] = "E.F.",
    ["FINANCE"] = "ECONOMIA",
    ["MUSIC"] = "MUSICA",
    ["MATHS"] = "MATES",
    ["ART"] = "PLASTICA",

    --- the run --------------------------------------------------------------

    ["LV %d"] = "NV %d",
    ["THE EYE"] = "EL OJO",
    ["THE EYE IS OPEN"] = "EL OJO ESTA ABIERTO",
    -- The drills and the surges (`DRILLS` and `SURGES` in src/spawner.lua),
    -- which the run says the once, the first time each one happens. They are
    -- copy rather than labels -- the run is describing what has just started
    -- rather than naming a mechanic -- so the Spanish is written for the same
    -- effect and not word for word: THE BELL RINGS is the break-time bell, and
    -- SUENA EL TIMBRE is the sound a Spanish school makes at the same moment.
    ["A LINE ACROSS THE PAGE"] = "UNA LINEA CRUZA LA HOJA",
    ["A CIRCLE IS DRAWN"] = "SE DIBUJA UN CIRCULO",
    ["ONE MARGIN CROWDS"] = "UN MARGEN SE LLENA",
    ["BOTH MARGINS AT ONCE"] = "LOS DOS MARGENES A LA VEZ",
    ["THE TABLE FILLS IN"] = "LA TABLA SE RELLENA",
    ["THE BELL RINGS"] = "SUENA EL TIMBRE",
    ["THE ROOM SETTLES"] = "LA CLASE SE CALMA",
    ["MORE OF THE SAME"] = "MAS DE LO MISMO",
    -- And the blow-up (Spawner:blown), which is the one of these that is not an
    -- event: it names a monster rather than a moment. "TRES VECES MAS GRANDE"
    -- over a literal "dibujado tres veces" for that reason -- what the line has
    -- to say is the size, and Spanish says a size that way. It is also the one
    -- line in this table that has to stay a *number*: a champion is twice the
    -- size and unannounced, so what this says is which of the two just walked on.
    ["DRAWN THREE TIMES THE SIZE"] = "TRES VECES MAS GRANDE",
    -- And the enraged one (Spawner:fury), which is the other line here that names
    -- a monster rather than a moment -- and the one that has to name a *pen*. A
    -- red-pen correction over the top of your work is the same thing in a Spanish
    -- exercise book as in an English one, and "REPASADO EN ROJO" is what a
    -- teacher has done to it: gone back over it in red. The literal "boligrafo
    -- rojo" says which pen at the cost of saying what happened, and what the
    -- player has to read off this line in three seconds is that the thing on the
    -- page has been marked.
    ["GONE OVER IN RED PEN"] = "REPASADO EN ROJO",
    -- The two cards a run can end on share their score line, since they are
    -- reporting the same two numbers about the same run. Its spacing is wider
    -- than the HUD's line above: a card has room and a bottom edge does not.
    ["%s   %d KILLS"] = "%s   %d BAJAS",

    -- The multikill word (src/multikill.lua), four a lesson and picked for
    -- what the word itself is rather than for staying close to the English --
    -- a shout only lands if it sounds like one. MUSIC's four are Italian
    -- dynamics and tempo marks, which is what Spanish sheet music calls them
    -- too, so none of the four gets a line here: an un-translated key falls
    -- through to the English and the English is already the right word.
    ["SCIENCE!"] = "CIENCIA!",
    ["EXTINCT"] = "EXTINTO",
    ["DEAD"] = "MUERTO",
    ["ATOMIC!"] = "ATOMICO!",
    ["YEAH"] = "SI",
    ["WOW"] = "GUAU",
    ["HUH"] = "EH",
    -- GUAY is the S GUAY's own word (COOL S, above) -- the same slang for the
    -- same feeling, so a run that has read one card already owns the other.
    ["NICE!"] = "GUAY!",
    ["SUMMED"] = "SUMADO",
    ["SUBSTRACTED"] = "RESTADO",
    ["INTEGRATED"] = "INTEGRADO",
    -- Coined exactly as the English is: nobody conjugates a mathematician's
    -- name in either language, which is the joke both times.
    ["FOURIER'D"] = "FOURIERIZADO",
    ["SWEAT!"] = "SUDOR!",
    ["RUN!"] = "CORRE!",
    ["FASTER!"] = "MAS RAPIDO!",
    ["GOAL!"] = "GOL!",
    ["ERASED"] = "BORRADO",
    ["INKED"] = "ENTINTADO",
    ["FINISHED"] = "TERMINADO",
    ["PASTED"] = "PEGADO",
    ["ALIGNED"] = "ALINEADO",
    ["PUMPED"] = "INFLADO",
    ["LIQUIDITY"] = "LIQUIDEZ",
    -- The same word both sides, the way HALO and CORRAL are (see the tool
    -- lines block below): a KPI is a KPI in Spanish business jargon too, and
    -- verbing it the English way is the whole joke either language tells.
    ["KPI'D"] = "KPI'D",

    --- the pause card -------------------------------------------------------

    ["PAUSED"] = "EN PAUSA",
    ["QUIT?"] = "¿SALIR?",
    -- The dev toggle's two switches, one line each, and the two words the touch
    -- row reads its state out in. The labels on its boxes are TOOLS and WEAPONS,
    -- which the library already asked for above.
    ["T: EVERY TOOL MAXED"] = "T: UTILES AL MAXIMO",
    ["T: HAND THE TOOLS BACK"] = "T: DEVOLVER LOS UTILES",
    ["W: EVERY WEAPON MAXED"] = "W: ARMAS AL MAXIMO",
    ["W: HAND THE WEAPONS BACK"] = "W: DEVOLVER LAS ARMAS",
    ["ON"] = "SI",
    ["OFF"] = "NO",

    --- the draft ------------------------------------------------------------

    ["LEVEL %d"] = "NIVEL %d",
    ["NEW"] = "NUEVO",
    ["MAX"] = "TOPE",
    ["SCRIBBLE THE BOX UNDER A CARD"] = "GARABATEA LA CASILLA DE UNA CARTA",
    -- Kept for the tap route the draft still carries behind a flag
    -- (`TAP_CARDS`, src/levelup.lua), which is a line it would say again.
    ["TAP A CARD OR SCRIBBLE ITS BOX"] = "TOCA UNA CARTA O SU CASILLA",
    ["OR PRESS 1 2 3"] = "O PULSA 1 2 3",

    --- the game over card ---------------------------------------------------

    ["CLASS DISMISSED"] = "SE ACABO LA CLASE",
    ["GAME OVER"] = "FIN DEL JUEGO",
    ["RETRY"] = "OTRA VEZ",
    ["QUIT"] = "SALIR",

    --- the retake card ------------------------------------------------------

    -- The card the death card is replaced by for a run with a retake left
    -- (src/retake.lua). QUEDAN rather than a translation of CHARGES: the count is
    -- the whole of the line and the Spanish says what is left of them in one word
    -- where the English needs two.
    ["ANOTHER CHANCE"] = "OTRA OPORTUNIDAD",
    ["RETAKING"] = "RECUPERANDO",
    ["%d/%d CHARGES LEFT"] = "QUEDAN %d/%d",

    --- the win card ---------------------------------------------------------

    ["THE EYE IS SHUT"] = "EL OJO ESTA CERRADO",
    ["YOU WIN"] = "HAS GANADO",
    ["EYE %d DOWN"] = "OJO %d CAIDO",
    ["END"] = "FIN",
    ["ENDLESS"] = "SIN FIN",
    ["OR PRESS 1 OR 2"] = "O PULSA 1 O 2",

    --- the tools -----------------------------------------------------------

    ["PENCIL"] = "LAPIZ",
    ["PEN"] = "BOLIGRAFO",
    ["RUBBER"] = "GOMA",
    ["HIGHLIGHTER"] = "SUBRAYADOR",
    ["GLUESTICK"] = "PEGAMENTO",
    ["PUSHPIN"] = "CHINCHETA",
    ["STAPLER"] = "GRAPADORA",
    ["RULER"] = "REGLA",
    ["COMPASS"] = "COMPAS",
    ["CRAYON"] = "CERA",

    --- the catalogue: passive weapons --------------------------------------

    -- The two hands-free attacks. Neither name is here: SHOT and SWORD are both
    -- up in the boards block, since a line and the board it opens are the same
    -- word for the same thing.
    ["A SHOT GOES OUT AT WHATEVER IS NEAREST"] =
        "SALE UN TIRO HACIA LO MAS CERCANO",
    ["THE SHOT COMES ROUND HALF AGAIN AS OFTEN"] =
        "EL TIRO SALE LA MITAD MAS A MENUDO",
    ["THE PELLET FLIES HALF AGAIN AS FAST"] =
        "EL TIRO VUELA LA MITAD MAS RAPIDO",
    ["EACH PELLET HITS TWICE AS HARD"] = "CADA TIRO GOLPEA EL DOBLE",
    ["TWO PELLETS LEAVE ON EVERY BEAT"] = "SALEN DOS TIROS A LA VEZ",

    ["A SWORD CUTS AN ARC THROUGH WHAT IS CLOSE"] =
        "UNA ESPADA CORTA UN ARCO DE LO QUE ESTA CERCA",
    -- "LA ESPADA" rather than "LA HOJA" for the blade: `hoja` is the sheet of
    -- paper everywhere else in this file (see the scissors' last level), and one
    -- word meaning two things is the trap the English keys are already held to.
    ["THE BLADE REACHES FURTHER OUT"] = "LA ESPADA LLEGA MAS LEJOS",
    ["THE ARC SWEEPS WIDER THAN A HALF CIRCLE"] =
        "EL ARCO BARRE MAS DE MEDIO CIRCULO",
    ["WHAT SURVIVES THE CUT IS KNOCKED BACK"] =
        "LO QUE SOBREVIVE AL CORTE SALE EMPUJADO",
    ["THE SWING GOES ALL THE WAY ROUND"] = "EL GOLPE DA LA VUELTA COMPLETA",

    ["STARS"] = "ESTRELLAS",
    ["A STAR ORBITS YOU AND CUTS WHAT IT TOUCHES"] =
        "UNA ESTRELLA TE ORBITA Y CORTA LO QUE TOCA",
    ["A SECOND STAR JOINS THE ORBIT"] = "UNA SEGUNDA ESTRELLA SE UNE A LA ORBITA",
    ["THE ORBIT TURNS TWICE AS FAST"] = "LA ORBITA GIRA EL DOBLE DE RAPIDO",
    ["A THIRD STAR MAKES IT A TRIANGLE"] = "UNA TERCERA LO VUELVE UN TRIANGULO",
    ["THE ORBIT SWELLS AND SHRINKS AS IT TURNS"] =
        "LA ORBITA CRECE Y SE ENCOGE AL GIRAR",

    ["ROCKET"] = "COHETE",
    ["TWO ROCKETS GO OFF IN DIRECTIONS NOBODY PICKED"] =
        "SALEN DOS COHETES SIN APUNTAR A NADA",
    ["FOUR GO OFF AT ONCE, THROUGH TWO THINGS EACH"] =
        "SALEN CUATRO A LA VEZ Y ATRAVIESAN DOS CADA UNO",
    ["THEY CARRY ON THROUGH THREE"] = "SIGUEN A TRAVES DE TRES",
    ["EACH ONE BURSTS IN A CIRCLE WHERE IT STOPS"] =
        "CADA UNO ESTALLA EN UN CIRCULO DONDE PARA",
    ["EIGHT GO OFF AT ONCE, ONE EVERY WAY"] =
        "SALEN OCHO A LA VEZ UNO HACIA CADA LADO",

    ["SUN"] = "SOL",
    ["A SUN RISES IN A CORNER AND BURNS WHAT IT COVERS"] =
        "UN SOL SALE EN UNA ESQUINA Y QUEMA LO QUE CUBRE",
    ["IT BURNS DEEPER AND HANGS ABOUT LONGER"] = "QUEMA MAS HONDO Y SE QUEDA MAS",
    ["IT REACHES FURTHER AND PULSES AS IT BURNS"] =
        "LLEGA MAS LEJOS Y LATE MIENTRAS QUEMA",
    ["A SECOND SUN RISES IN THE OPPOSITE CORNER"] =
        "UN SEGUNDO SOL SALE EN LA ESQUINA OPUESTA",
    ["SUNRAYS SHOOT OUT OF IT ACROSS THE PAGE"] =
        "LE SALEN RAYOS QUE CRUZAN LA HOJA",

    ["COOL S"] = "S GUAY",
    ["A COOL S FLOATS IN AND CUTS A LINE THROUGH WHERE YOU STAND"] =
        "UNA S GUAY ENTRA Y CORTA UNA LINEA POR DONDE ESTAS",
    ["IT BOUNCES OFF THE EDGE OF THE PAGE"] = "REBOTA EN EL BORDE DE LA HOJA",
    ["ONE COMES IN TWICE AS OFTEN"] = "ENTRA EL DOBLE DE A MENUDO",
    ["YOUR PEN LINES BOUNCE IT TOO"] = "TUS LINEAS DE BOLIGRAFO TAMBIEN LA REBOTAN",
    ["ONE S STAYS ON THE PAGE FOR GOOD, BOUNCING FOREVER"] =
        "UNA S SE QUEDA EN LA HOJA REBOTANDO PARA SIEMPRE",

    ["LASER BEAM"] = "RAYO LASER",
    ["A BEAM FIRES DOWN THE LINE YOU ARE WALKING"] =
        "UN RAYO SALE POR LA LINEA QUE ANDAS",
    ["THE BEAM HOLDS INSTEAD OF FLASHING"] = "EL RAYO AGUANTA EN VEZ DE DESTELLAR",
    ["IT COMES ROUND TWICE AS OFTEN"] = "LLEGA EL DOBLE DE A MENUDO",
    ["THE BEAM CUTS A WIDER BAND"] = "EL RAYO CORTA UNA BANDA MAS ANCHA",
    ["A SECOND BEAM FIRES OUT BEHIND YOU"] = "UN SEGUNDO RAYO SALE A TU ESPALDA",

    ["BOMB"] = "BOMBA",
    ["A BOMB DROPS AT YOUR FEET AND BLOWS UP WHAT IS STILL THERE"] =
        "UNA BOMBA CAE A TUS PIES Y VUELA LO QUE SIGA AHI",
    ["THE BLAST REACHES HALF AGAIN AS FAR"] = "LA EXPLOSION LLEGA LA MITAD MAS LEJOS",
    ["ONE DROPS TWICE AS OFTEN"] = "CAE EL DOBLE DE A MENUDO",
    ["THE FUSE BURNS TWICE AS FAST"] = "LA MECHA ARDE EL DOBLE DE RAPIDO",
    ["THE CRATER GOES ON BURNING AFTER THE BANG"] =
        "EL CRATER SIGUE ARDIENDO TRAS EL ESTALLIDO",

    ["SKATE"] = "MONOPATIN",
    ["A SKATE LEAVES A TRAIL THAT CUTS WHAT FOLLOWS YOU"] =
        "UN MONOPATIN DEJA UN RASTRO QUE CORTA LO QUE TE SIGUE",
    ["WHAT STANDS IN THE TRAIL LOSES ITS FOOTING"] =
        "LO QUE PISA EL RASTRO PIERDE EL EQUILIBRIO",
    ["THE TRAIL CUTS FAR DEEPER INTO WHAT STANDS IN IT"] =
        "EL RASTRO CORTA MUCHO MAS HONDO A QUIEN LO PISA",
    ["YOU RIDE THE FRESH END OF YOUR OWN TRAIL FASTER"] =
        "VAS MAS RAPIDO POR EL TRAMO FRESCO DE TU RASTRO",
    ["EVERY GEM ON THE TRAIL COMES TO YOU"] = "CADA GEMA DEL RASTRO VIENE A TI",

    ["STORM"] = "TORMENTA",
    ["A CLOUD ROLLS IN AND STRIKES THE CROWD WITH LIGHTNING"] =
        "UNA NUBE ENTRA Y GOLPEA A LA HORDA CON UN RAYO",
    ["THE BOLT TAKES A WIDER CIRCLE WITH IT"] =
        "EL RAYO SE LLEVA UN CIRCULO MAS ANCHO",
    ["A SECOND CLOUD ROLLS IN WITH IT"] = "UNA SEGUNDA NUBE ENTRA CON ELLA",
    ["A CLOUD STAYS AND STRIKES TWICE MORE BEFORE IT GOES"] =
        "UNA NUBE SE QUEDA Y GOLPEA DOS VECES MAS ANTES DE IRSE",
    ["WHAT SURVIVES A BOLT PASSES IT ON TO WHOEVER IS NEAR"] =
        "QUIEN SOBREVIVE A UN RAYO SE LO PASA A QUIEN TIENE CERCA",

    ["M BIRDS"] = "PAJAROS M",
    ["A BIRD WHEELS ROUND YOU AND NICKS WHAT IT PASSES"] =
        "UN PAJARO TE RONDA Y PICA LO QUE ROZA",
    ["A FLOCK OF FIVE COMES WITH IT"] = "LLEGA UNA BANDADA DE CINCO",
    ["EVERY BIRD BITES THREE TIMES AS DEEP"] = "CADA PAJARO PICA EL TRIPLE DE HONDO",
    ["THREE MORE JOIN AND SOME FETCH YOUR GEMS"] =
        "SE UNEN TRES MAS Y ALGUNOS TE TRAEN LAS GEMAS",
    ["THE FLOCK BECOMES A SWARM ALL OVER THE PAGE"] =
        "LA BANDADA SE VUELVE UN ENJAMBRE POR TODA LA HOJA",

    ["SPIRALS"] = "ESPIRALES",
    ["A SPIRAL WINDS ONTO THE PAGE AND DRAWS THE CROWD IN"] =
        "UNA ESPIRAL SE DIBUJA Y ATRAE A LA HORDA",
    ["TWO WIND ON AT ONCE AND TWICE AS OFTEN"] =
        "SE DIBUJAN DOS A LA VEZ Y EL DOBLE DE A MENUDO",
    ["THEY REACH FURTHER ACROSS THE PAGE"] = "LLEGAN MAS LEJOS POR LA HOJA",
    ["WHAT THEY CATCH IS HELD IN FOR LONGER"] =
        "LO QUE ATRAPAN SE QUEDA DENTRO MAS TIEMPO",
    ["ONE WINDS ROUND YOU AND PUSHES INSTEAD OF PULLING"] =
        "UNA TE RODEA Y EMPUJA EN VEZ DE ATRAER",

    --- the catalogue: passives ---------------------------------------------

    ["MAGNET"] = "IMAN",
    ["XP COMES TO YOU FROM FURTHER OFF"] = "LA XP TE LLEGA DESDE MAS LEJOS",
    ["FURTHER OFF AGAIN"] = "DESDE MAS LEJOS OTRA VEZ",
    ["THE WHOLE PAGE LEANS YOUR WAY"] = "TODA LA HOJA SE INCLINA HACIA TI",

    ["TOP MARKS"] = "SOBRESALIENTE",
    ["EVERY GEM IS WORTH MORE EXPERIENCE"] = "CADA GEMA VALE MAS EXPERIENCIA",
    ["WORTH MORE AGAIN"] = "VALE MAS OTRA VEZ",
    ["FULL MARKS FOR EVERYTHING YOU PICK UP"] = "NOTA MAXIMA POR TODO LO QUE COGES",

    ["SHARPENER"] = "SACAPUNTAS",
    ["+20% DAMAGE FROM WHAT YOU DRAW"] = "+20% DE DAÑO DE LO QUE DIBUJAS",
    ["+20% DAMAGE FROM WHAT FIGHTS FOR YOU"] = "+20% DE DAÑO DE LO QUE PELEA POR TI",
    ["+25% MORE ON TOP OF THAT"] = "+25% MAS ENCIMA DE ESO",
    ["+30% MORE ON TOP OF THAT"] = "+30% MAS ENCIMA DE ESO",
    ["+40% MORE ON TOP OF THAT"] = "+40% MAS ENCIMA DE ESO",

    ["GRAPHITE"] = "GRAFITO",

    ["METRONOME"] = "METRONOMO",
    ["EVERYTHING THAT FIGHTS FOR YOU COMES ROUND SOONER"] =
        "TODO LO QUE PELEA POR TI LLEGA ANTES",
    ["SOONER AGAIN"] = "ANTES OTRA VEZ",
    ["NOTHING ON THE PAGE WAITS ITS TURN"] = "NADA EN LA HOJA ESPERA SU TURNO",

    ["INKWELL"] = "TINTERO",
    ["+30 INK IN THE WELL, AND +30 IN IT NOW"] = "+30 DE TINTA EN EL TINTERO Y +30 YA",
    ["+40 INK IN THE WELL, AND +40 IN IT NOW"] = "+40 DE TINTA EN EL TINTERO Y +40 YA",

    ["CARTRIDGE"] = "CARTUCHO",
    ["INK COMES BACK FASTER"] = "LA TINTA VUELVE MAS RAPIDO",
    ["AND STARTS COMING BACK SOONER"] = "Y EMPIEZA A VOLVER ANTES",
    ["FASTER AGAIN"] = "MAS RAPIDO OTRA VEZ",
    ["THE NIB NEVER RUNS DRY"] = "LA PLUMILLA NUNCA SE SECA",

    ["BLOTTER"] = "SECANTE",
    ["EVERYTHING YOU DRAW COSTS LESS INK"] = "TODO LO QUE DIBUJAS CUESTA MENOS TINTA",
    ["LESS AGAIN"] = "MENOS OTRA VEZ",
    ["NOTHING SOAKS INTO THE PAGE UNUSED"] = "NADA SE CUELA EN LA HOJA SIN USAR",

    ["FIXATIVE"] = "FIJADOR",
    ["WHAT YOU DRAW LASTS LONGER AND HOLDS LONGER"] =
        "LO QUE DIBUJAS DURA Y SUJETA MAS",
    ["LONGER AGAIN"] = "MAS OTRA VEZ",
    ["IT SETS ON THE PAGE AND STAYS SET"] = "SE FIJA EN LA HOJA Y AHI SE QUEDA",

    ["LAMINATE"] = "PLASTIFICADO",
    ["WHAT FIGHTS FOR YOU LASTS LONGER AND HOLDS LONGER"] =
        "LO QUE PELEA POR TI DURA Y SUJETA MAS",
    ["SEALED IN AND NOTHING WEARS IT OFF"] = "SELLADO Y NADA LO BORRA",

    ["PAPER PLANE"] = "AVION PAPEL",
    ["YOU MOVE FASTER"] = "TE MUEVES MAS RAPIDO",
    ["OFF ACROSS THE PAGE"] = "CRUZANDO LA HOJA VOLANDO",

    ["FRESH PAGE"] = "HOJA NUEVA",
    ["+20 MAX HEALTH AND +20 BACK NOW"] = "+20 DE VIDA MAXIMA Y +20 YA",
    ["+30 MAX HEALTH AND +30 BACK NOW"] = "+30 DE VIDA MAXIMA Y +30 YA",

    ["SELLOTAPE"] = "CELO",
    ["TORN PAGES MEND: YOU HEAL AS YOU GO"] = "LA HOJA ROTA SE PEGA: TE CURAS ANDANDO",
    ["THE TEAR CLOSES BEHIND YOU"] = "EL DESGARRO SE CIERRA TRAS DE TI",

    ["BANDAID"] = "TIRITA",
    ["WHAT FIGHTS FOR YOU PATCHES YOU UP AS IT CUTS"] =
        "LO QUE LUCHA POR TI TE CURA AL CORTAR",
    ["MORE COMES BACK"] = "VUELVE MAS",
    ["MORE AGAIN"] = "MAS OTRA VEZ",
    ["EVERY CUT THEY DEAL CLOSES ONE OF YOURS"] = "CADA CORTE QUE DAN CIERRA UNO TUYO",

    --- the catalogue: the tool lines ---------------------------------------

    -- The line's own name, which is not always the tool's: the marker line hands
    -- you the highlighter.
    ["MARKER"] = "ROTULADOR",

    -- The fusions (`needs` and `fuses` in src/upgrades.lua). HALO is the same
    -- word in both languages -- it is what the tool leaves lying on the page, and
    -- a ring of light is called that either side of the border -- so like the
    -- title on the front of the book it is a name rather than a line of copy, and
    -- it is here only so that nothing has to wonder whether it was forgotten.
    ["HALO"] = "HALO",
    ["THE MARKER GOES IN THE COMPASS: A RING THAT BURNS"] =
        "EL ROTULADOR VA EN EL COMPAS: UN ANILLO QUE QUEMA",
    -- LASSO is a name too, but not a shared one: the pencil's own finale already
    -- calls the thing a LAZO two shelves down, so the tool that draws one for you
    -- is called the same word the level that taught you the trick is.
    ["LASSO"] = "LAZO",
    ["THE PENCIL GOES IN THE COMPASS: A RING THAT CLOSES"] =
        "EL LAPIZ VA EN EL COMPAS: UN ANILLO QUE SE CIERRA",
    -- MOAT is a name as well, and the one of the three that had a Spanish word
    -- waiting for it: a foso is the ring of ground round a castle nothing gets
    -- across, which is exactly what the tool leaves lying on the page.
    ["MOAT"] = "FOSO",
    ["THE GLUESTICK GOES IN THE COMPASS: A RING THAT HOLDS"] =
        "EL PEGAMENTO VA EN EL COMPAS: UN ANILLO QUE ATRAPA",
    -- And PUNCH is the fourth name, translated rather than kept: a perforadora is
    -- the thing in a pencil case that takes circles out of paper, which is what
    -- the tool is, and it is the longest name in either language at eleven
    -- characters -- exactly PAPER PLANE's, which is what the draft card is already
    -- sized to print beside an icon.
    ["PUNCH"] = "PERFORADORA",
    ["THE SCISSORS GO IN THE COMPASS: A RING THAT LIFTS OUT"] =
        "LAS TIJERAS VAN EN EL COMPAS: UN ANILLO QUE SE LEVANTA",
    -- SPINDLE is the fifth, and a pincho is the spike on a desk that paper gets
    -- pushed onto -- which is what the tool leaves standing in the page with
    -- something on it. The English word carries a second meaning the Spanish does
    -- not, and it is the reason it was picked: a spindle is also the axis a thing
    -- turns about.
    ["SPINDLE"] = "PINCHO",
    ["THE PUSHPIN GOES IN THE COMPASS: IT DRAGS AND PINS"] =
        "LA CHINCHETA VA EN EL COMPAS: ARRASTRA Y CLAVA",
    -- And CORRAL is the sixth, the same word in both languages the way HALO is --
    -- and unlike the halo it is the same word for the same reason the English one
    -- was picked: a corral is a closed fence with something inside it, which is
    -- what the tool leaves lying on the page, and a *pen* is that word too. The
    -- pun survives the border by luck, which is the only fusion name so far that
    -- can be said of. Here so that nothing has to wonder whether it was forgotten.
    ["CORRAL"] = "CORRAL",
    ["THE PEN GOES IN THE COMPASS: A RING THEY CANNOT CROSS"] =
        "EL BOLIGRAFO VA EN EL COMPAS: UN ANILLO QUE NO CRUZAN",
    -- And HEM is the seventh, translated rather than kept: a dobladillo is the
    -- edge of a cloth turned under and fastened all the way round, which is what
    -- the tool leaves and what the English word means. Ten characters against
    -- PERFORADORA's eleven, so it still fits the card the draft was sized for.
    ["HEM"] = "DOBLADILLO",
    ["THE STAPLER GOES IN THE COMPASS: A RING OF STAPLES"] =
        "LA GRAPADORA VA EN EL COMPAS: UN ANILLO DE GRAPAS",
    -- And CLEARING is the eighth, and the one whose Spanish is the better word of
    -- the two: un claro is a circle of ground in a wood with nothing standing in
    -- it, which is exactly what the tool leaves and is five characters where the
    -- English is eight. Both words mean the space rather than the ring round it,
    -- which is the point -- it is the one fusion named after the middle.
    ["CLEARING"] = "CLARO",
    ["THE RUBBER GOES IN THE COMPASS: IT SWEEPS IT CLEAR"] =
        "LA GOMA VA EN EL COMPAS: LO BARRE TODO FUERA",
    -- And FOLD is the ninth, and the only unlock line of the nine that does not
    -- say GOES IN THE COMPASS -- because nothing goes in it: the two circles do the
    -- work between them. A pliegue is the crease a sheet of paper takes when it is
    -- folded, which is what a ruler laid across a page and pressed down leaves, and
    -- it is what the construction is *for* on real paper. Seven characters against
    -- PERFORADORA's eleven, so the card the draft was sized for still holds it.
    ["FOLD"] = "PLIEGUE",
    ["TWO CIRCLES CROSSING: A RULER FALLS BETWEEN"] =
        "DOS CIRCULOS QUE SE CRUZAN: CAE UNA REGLA EN MEDIO",
    -- And the three off the pushpin, which are the first fusion names that are
    -- not a thing the compass left behind. All three unlocks say JOINS THE PINS
    -- where the nine above say GOES IN THE COMPASS, and the Spanish keeps that
    -- parallel: UNE LAS CHINCHETAS on all three, so a player who has read one of
    -- them knows what the family is before reading the rest of the card.
    --
    -- DOT TO DOT is the name of the puzzle rather than a description of the tool,
    -- and it is the one name here that had to lose a word crossing the border: the
    -- Spanish for the puzzle is "une los puntos", and the article is what goes,
    -- since PERFORADORA's eleven characters are the whole budget a draft card has.
    -- UNE PUNTOS reads as the instruction printed over the dots, which is what the
    -- English is too.
    ["DOT TO DOT"] = "UNE PUNTOS",
    ["THE PENCIL JOINS THE PINS: A SHAPE THAT CUTS"] =
        "EL LAPIZ UNE LAS CHINCHETAS: UNA FORMA QUE CORTA",
    -- STOCKADE is translated rather than kept, and an estacada is the better word
    -- of the two for once: it is a fence of *driven stakes*, which is exactly what
    -- a pin is and exactly what this tool builds a wall out of. Eight characters
    -- either side of the border, which is the tidiest name in the section.
    ["STOCKADE"] = "ESTACADA",
    ["THE PEN JOINS THE PINS: A FENCE WITH POSTS"] =
        "EL BOLIGRAFO UNE LAS CHINCHETAS: UNA VALLA CON POSTES",
    -- And CORDON is the same word in both languages, the way HALO and CORRAL are,
    -- and for CORRAL's reason rather than the halo's: acordonar is what you do with
    -- tape and two posts to say a stretch of ground is not to be crossed, so the
    -- word means the same thing about the same object either side. Here so that
    -- nothing has to wonder whether it was forgotten.
    ["CORDON"] = "CORDON",
    ["THE MARKER JOINS THE PINS: A BAND THAT BURNS"] =
        "EL ROTULADOR UNE LAS CHINCHETAS: UNA BANDA QUE QUEMA",
    -- And the four that are not a nib strung between two pins. Two of them cast a
    -- whole second tool along the line the pins aim and two pool round a single
    -- pin, so none of them can say JOINS THE PINS and none of them does -- the
    -- unlock is where a player finds out which of the three shapes this row is,
    -- and the Spanish keeps that split rather than smoothing it over.
    --
    -- SNAP LINE is a cord pinned at both ends and snapped flat against a surface,
    -- which is how anybody has ever ruled a line longer than their ruler. The
    -- Spanish names the tool rather than the line -- un cordel trazador is the
    -- thing itself -- and TRAZADOR is the half of that name that carries the
    -- meaning, at eight characters against PERFORADORA's eleven.
    ["SNAP LINE"] = "TRAZADOR",
    ["THE PINS AIM A RULER FROM EDGE TO EDGE"] =
        "LAS CHINCHETAS APUNTAN UNA REGLA DE BORDE A BORDE",
    -- And TEAR LINE is the line a page comes apart along. The Spanish names the
    -- tear instead of the line, which is the CLEARING's swap -- un claro is the
    -- space and not the ring round it -- and un rasgon is what is left in a sheet
    -- of paper afterwards.
    ["TEAR LINE"] = "RASGON",
    ["THE PINS TEAR THE PAGE FROM EDGE TO EDGE"] =
        "LAS CHINCHETAS RASGAN LA HOJA DE BORDE A BORDE",
    -- TACK is the family's one pun and the CORRAL's kind of pun: a tack *is* a
    -- pushpin and *tacky* is what glue is, so the English word is both parents at
    -- once. Unlike the corral's it does not survive the border -- chincheta says
    -- nothing about being sticky -- so the Spanish drops the pin and names the
    -- blob: un pegote is a lump of paste stuck where it landed, and pegar is the
    -- verb under it.
    ["TACK"] = "PEGOTE",
    ["A PIN IN A POOL OF PASTE: IT HOLDS WHAT IT SPARED"] =
        "UNA CHINCHETA EN PEGAMENTO: ATRAPA LO QUE PERDONA",
    -- And CRATER is the same word in both languages, the way HALO, CORRAL and
    -- CORDON are -- and for a reason none of those three had: it is a word the
    -- pushpin's own row has been using for its circle since the day it was
    -- written, in a game where nothing else has one. The tool is named after the
    -- thing its parent always claimed to leave and never quite did.
    ["CRATER"] = "CRATER",
    ["A PIN THAT THROWS OUT WHAT IT DID NOT KILL"] =
        "UNA CHINCHETA QUE EXPULSA LO QUE NO MATA",
    -- And the last one off the pushpin, which is the only fusion whose parents
    -- share a gesture and the only name in the family that describes neither a
    -- mark nor a tool. It describes a *rate*: several loosed one after another and
    -- judged together rather than one at a time, which is the whole of what this
    -- row does to the pin. VOLLEY sits with STOCKADE, CORDON, MOAT and CORRAL in
    -- the one register this game's fusion names keep coming back to, and it is the
    -- only one of the five that is not an enclosure.
    --
    -- The Spanish is not the dictionary word. An *andanada* is a broadside, which
    -- is right and is nine characters of a card that has eleven; a *rafaga* is a
    -- burst -- of wind, or of gunfire -- and it is what anybody would actually say
    -- about a run of something coming out faster than you can count. Six
    -- characters, and the accent goes the way CORDON's and RASGON's did, since the
    -- font has no accented vowels and never needed any.
    --
    -- The unlock says both halves of the gesture, and the Spanish borrows the
    -- second from the stapler's own finale rather than inventing a word for it:
    -- that level is COSER UNA FILA, so a seam of pins is UNA FILA here too and a
    -- player who has finished the stapler is reading a word they already own.
    ["VOLLEY"] = "RAFAGA",
    ["A PIN THAT DOES NOT FALL, AND A SEAM IF YOU DRAG"] =
        "UNA CHINCHETA QUE NO CAE, Y UNA FILA SI ARRASTRAS",

    -- **And then the ruler's seven**, which are the last family and the one whose
    -- names had the least room to invent anything: all seven are the same object
    -- doing the same thing, so what each name has to carry is the *mark*, and the
    -- mark is the second parent. Every one of them is a real word for a real thing
    -- on a real page, which is the register the whole catalogue has been in since
    -- CORRAL.
    --
    -- MARGIN is the same word in both languages, and it is not a translation
    -- coincidence -- it is the same object. A margin is two ruled lines with a lane
    -- between them, drawn down the side of a page with a pencil and a ruler, which
    -- is what this row does and how it does it.
    ["MARGIN"] = "MARGEN",
    ["IT RULES A LINE DOWN EITHER SIDE OF THE BAND"] =
        "RAYA UNA LINEA A CADA LADO DE LA BANDA",
    -- SPINE is the one line on a notebook a page cannot be crossed at, and the
    -- Spanish is the bookbinder's word rather than the anatomist's: *el lomo* is
    -- the spine of a book and nothing else, where *columna* would be a backbone. It
    -- is four characters, which makes it the shortest name in the game.
    ["SPINE"] = "LOMO",
    ["IT RULES A WALL FROM ONE EDGE TO THE OTHER"] =
        "RAYA UN MURO DE UN BORDE AL OTRO",
    -- UNDERLINE is what a student does with these two objects, and it is also what
    -- the tool does with its fields -- the band is drawn *under* every other mark on
    -- the page, and has been since long before there was a ruler to draw it
    -- against. The Spanish cannot have it: SUBRAYADO is the marker's own name
    -- (SUBRAYADOR) with one letter off, and two cards a letter apart on one strip
    -- is a strip nobody can read. So the Spanish names the band instead -- *una
    -- franja* is a broad stripe across something -- which is the CLEARING's swap and
    -- the TEAR LINE's: where the pun will not cross the border, name the mark.
    ["UNDERLINE"] = "FRANJA",
    ["IT RULES A BURNING BAND ACROSS THE PAGE"] =
        "RAYA UNA BANDA ARDIENDO POR TODA LA HOJA",
    -- TRENCH is the MOAT's word one shape over, and the pair is deliberate: the
    -- gluestick's two barriers are both named for earthworks, one round and one
    -- straight. Both languages keep it.
    ["TRENCH"] = "TRINCHERA",
    ["IT RULES A BAR OF PASTE THEY STICK FAST IN"] =
        "RAYA UNA BARRA DE PEGAMENTO DONDE SE QUEDAN",
    -- PARTING is the page opening along a line, and the Spanish is the rubber's
    -- other fusion's word taken one step further: the CLEARING is *un claro* and
    -- this is *un despeje*, which is what you call clearing something away rather
    -- than the clearing it leaves. The obvious Spanish for a parting is *una raya*,
    -- and it is exactly the word this file uses as a *verb* on half the pencil's
    -- line and the ruler's finale -- a name that reads as an instruction everywhere
    -- else on the strip is a name that has to go.
    ["PARTING"] = "DESPEJE",
    ["THE WHOLE PAGE IS THROWN CLEAR OF THE LINE"] =
        "TODA LA HOJA SALE DESPEDIDA LEJOS DE LA LINEA",
    -- SEAM is the stapler's own word -- its finale is a seam and the HEM is one
    -- closed -- and the Spanish keeps the sewing register the whole stapler line is
    -- written in: *una costura* is a seam, *un dobladillo* is the hem, and *coser
    -- una fila* is the level that started it.
    ["SEAM"] = "COSTURA",
    ["IT RULES A SEAM OF STAPLES ACROSS THE PAGE"] =
        "RAYA UNA FILA DE GRAPAS POR TODA LA HOJA",
    -- And GUILLOTINE, which is the same word in both languages and is a real thing
    -- in a real stationery cupboard rather than the one everybody pictures: a
    -- straight edge with a blade hinged to run down it, for trimming paper. Ten
    -- characters against a card that has eleven, which is the longest name in the
    -- game and fits.
    --
    -- The unlock has to say the cut *and* what chooses the half, because on this
    -- one row the choosing is done by walking rather than by tapping -- so it names
    -- the step. The Spanish says the same thing with the verb the scissors' own
    -- finale uses for a half leaving the page (SE VA), which a player who finished
    -- them is already reading.
    ["GUILLOTINE"] = "GUILLOTINA",
    ["IT TRIMS THE PAGE: THE HALF YOU STEP OFF GOES"] =
        "CORTA LA HOJA: LA MITAD QUE DEJAS SE VA",

    -- The six off the pencil, which is the first family whose names all describe
    -- a *line* rather than a shape left on the page -- so all six translate
    -- rather than being kept, where the compass's nine are half loanwords.
    --
    -- BARBA is the ragged untrimmed edge of a sheet of handmade paper, which is
    -- exactly what a deckle edge is called in a Spanish bindery and exactly what
    -- the tool draws: a fence with a torn edge. Five characters against the
    -- English seven, and both well inside a card.
    ["DECKLE"] = "BARBA",
    ["A FENCE YOU CAN CLOSE, AND WHAT IT SHUTS IN IS CUT"] =
        "UNA VALLA QUE PUEDES CERRAR: LO QUE ENCIERRA SE RAYA",
    -- CABO is the stub of a pencil worn down to nothing, and it is the better half
    -- of the English pun rather than the worse: a stub is both the nub of rubber on
    -- the ferrule and what is left of a pencil somebody has actually used, and the
    -- Spanish keeps the second while GOMA -- the rubber itself -- would have thrown
    -- it away and named the tool after only one of its two ends.
    ["STUB"] = "CABO",
    ["DRAW WITH THE POINT, TAP TO SHOVE THEM OFF IT"] =
        "DIBUJA CON LA PUNTA, TOCA PARA APARTARLOS",
    -- SANGRADO is what a printer calls ink running past the edge of the area it was
    -- laid for, the same word for the same thing in both trades -- and it carries
    -- the second meaning the English does too, which is why the word was picked in
    -- the first place: what the ring holds bleeds.
    ["BLEED"] = "SANGRADO",
    ["RING THEM WITH INK AND THE WHOLE PATCH CATCHES"] =
        "RODEALOS DE TINTA Y ARDE TODO EL CORRO",
    -- ARRASTRE is the one name in the family where the pun survives the border
    -- whole, the way CORRAL's does: arrastrar is to drag your finger across
    -- something and to drag something towards you, and the tool is both at once.
    ["DRAG"] = "ARRASTRE",
    ["THE LINE PULLS THEM ONTO ITSELF AS YOU DRAW"] =
        "LA LINEA TIRA DE ELLOS MIENTRAS DIBUJAS",
    -- RECORTE is the shape scissors take out of a sheet and the piece that comes
    -- away with it, which is both halves of what this does -- and it is the word
    -- the scissors' own last level is already using for the offcut, so a player who
    -- finished them is reading a word they know.
    ["CUTOUT"] = "RECORTE",
    -- The scissors' own finale one shape over, so it borrows that line's wording
    -- outright in both languages ("se va, y ellos con ella"): what the ring closes
    -- on is not deleted, it leaves with the paper -- and a player who read the
    -- parent's card is reading the same sentence about a circle. 41 characters
    -- against the longest card in the book at 58, and the Spanish is 43.
    ["THE RING TAKES THE PAGE, AND THEM WITH IT"] =
        "EL CORRO SE LLEVA LA HOJA, Y ELLOS CON ELLA",
    -- PUNTADA is a stitch in both senses the English name carries: what a needle
    -- makes and what a stapler makes, since the wire a stapler folds through paper
    -- is called a puntada in a Spanish bindery exactly as it is called a stitch in
    -- an English one. Eight characters, well inside a card.
    ["STITCH"] = "PUNTADA",
    ["A STAPLE AT EACH END, AND EVERY ONE GOES THROUGH"] =
        "UNA GRAPA EN CADA PUNTA, Y TODAS ATRAVIESAN",
    -- And the three off two brushes with no pencil in the pair. Same rule as the
    -- six above and for the same reason -- every one of these names is a line or
    -- the mark of one, and a line is a thing both languages have a word for.
    --
    -- TOPE is the stop a sheet runs up against in a press and the thing you bounce
    -- off everywhere else, which is both halves of the English name in the one word
    -- a Spanish printer would already be using.
    ["BUMPER"] = "TOPE",
    ["THE FENCE THROWS BACK WHATEVER WALKS INTO IT"] =
        "LA VALLA REBOTA A QUIEN CHOCA CON ELLA",
    -- GRUESO is not a translation of "swell", it is the better word: in Spanish
    -- calligraphy the heavy stroke of a letter is *el grueso* and the hairline is
    -- *el perfil*, which is the pair of nibs this row actually has -- so the name
    -- is what the tool lays when your hand slows down, said in the trade that has
    -- always had two names for it.
    ["SWELL"] = "GRUESO",
    ["A BURNING LINE, THICK WHEN YOU DRAW IT SLOWLY"] =
        "UNA LINEA QUE ARDE, GRUESA SI VAS DESPACIO",
    -- RASPON is the mark left by something dragged across paper rather than rubbed
    -- at it, which is the English name exactly. Its unlock keeps the STUB's own
    -- words for the tap -- TOCA PARA APARTARLOS -- because it is the same gesture
    -- doing the same thing, and a player who has read one should recognise the
    -- other rather than have to work it out twice.
    ["SCUFF"] = "RASPON",
    ["SWIPE TO BURN THEM, TAP TO SHOVE THEM OFF IT"] =
        "DESLIZA PARA QUEMARLOS, TOCA PARA APARTARLOS",
    -- The gluestick's three. Same rule again -- every one of these names is a mark
    -- or what a mark does -- and two of the three are the word the trade already
    -- uses in both languages.
    --
    -- PEGADO is what has happened to whatever is inside it, and it is a participle
    -- standing in for a noun exactly as SANGRADO is: the English name is the sheet
    -- that gets pasted down to the board, and the Spanish is the state of being
    -- stuck, which is the half a player is actually looking at.
    ["PASTEDOWN"] = "PEGADO",
    ["A WALL OF PASTE. NOTHING IN, NOTHING OUT"] =
        "UN MURO DE COLA: NADIE ENTRA, NADIE SALE",
    -- PULPA is the papermaking word in both languages for the slurry paper is made
    -- out of, and it carries the second meaning the English does too -- what the
    -- crowd is hauled into and then rubbed into being.
    ["PULP"] = "PULPA",
    ["THE SMEAR HAULS THEM IN AND HOLDS THEM THERE"] =
        "EL PEGOTE LOS ARRASTRA DENTRO Y LOS SUJETA",
    -- MORDIENTE is the same word for the same thing: the size a gilder lays down to
    -- make gold stick, from *mordere*, to bite. An adhesive whose name means biting,
    -- which is the row, and it needed no translating at all.
    ["MORDANT"] = "MORDIENTE",
    ["THE PASTE BURNS EVERYTHING IT HAS STUCK"] =
        "LA COLA QUEMA TODO LO QUE ATRAPA",
    -- The stapler's three. PALIZADA and ESTACADA are near-synonyms in Spanish
    -- exactly as PALING and STOCKADE are in English, which is the right answer
    -- rather than a collision: the two rows *are* the pen's two fences, one dragged
    -- and one built, and both languages have two words for a fence made of stakes.
    ["PALING"] = "PALIZADA",
    ["A FENCE STRUNG FROM STAPLE TO STAPLE"] =
        "UNA VALLA DE GRAPA EN GRAPA",
    -- MECHA is a wick and a fuse in one word, which is what the row is: a cord that
    -- burns along its own length and is held down while it does. The bomb's own line
    -- already calls its fuse a mecha, so a player who has read that is reading a word
    -- they know.
    ["WICK"] = "MECHA",
    ["A BURNING LINE STRUNG FROM STAPLE TO STAPLE"] =
        "UNA LINEA QUE ARDE DE GRAPA EN GRAPA",
    -- REMACHE is the trade's word for the folded-over leg of a fastener -- what a
    -- clinch actually is -- and it carries the same second meaning the English does:
    -- something driven home so it cannot come loose.
    ["CLINCH"] = "REMACHE",
    ["STAPLES THAT STAY, AND HOLD WHATEVER CROSSES THEM"] =
        "GRAPAS QUE SE QUEDAN Y SUJETAN A QUIEN LAS PISA",
    -- TIRON is the yank, which is the half of the English name a player actually
    -- sees: SNAG is the rubber catching on the wire and TIRON is what happens next,
    -- and Spanish has no one word that is both. It is also the noun of the verb the
    -- stapler's own third level already uses -- SE ARRANCA DE LA HOJA -- so a player
    -- who read that card is reading a word they know. Its unlock keeps the SCUFF's
    -- and the STUB's pairing, TOCA and DESLIZA, for their reason: the same two
    -- gestures told apart the same way should be told apart in the same words, even
    -- where this row is the one that swaps which of them is which.
    ["SNAG"] = "TIRON",
    ["TAP TO STAPLE THEM, SWIPE TO RIP IT BACK OUT"] =
        "TOCA PARA GRAPARLOS, DESLIZA PARA ARRANCARLA",
    -- BISAGRA is the hinge on a door and the hinge of a bound page in the same
    -- word, exactly as the English is, and it is a word everybody has -- which is
    -- the whole reason the row is not called after the bindery term either side of
    -- the border. Seven characters against PERFORADORA's eleven, so the card the
    -- draft was sized for holds it with room over.
    --
    -- The unlock keeps the order the English has, because the order *is* the
    -- gesture: the wire goes in first and the blades come down it afterwards. GRAPA
    -- and CORTA are the two verbs the stapler's and the scissors' own lines already
    -- use, so a player who finished both is reading two words they know. 45
    -- characters against the longest card in the book at 58.
    ["HINGE"] = "BISAGRA",
    ["IT STAPLES THE LINE, THEN CUTS THE PAGE ALONG IT"] =
        "GRAPA LA LINEA Y LUEGO CORTA LA HOJA POR ELLA",
    -- COLLAGE is the same word in both languages, which is the only name on the
    -- strip that needs no translation at all -- it is French in both, it means
    -- cut-and-paste in both, and it is the one row whose name *is* its mechanic.
    -- The entry is written anyway rather than left to the fallback, so that the
    -- table can be read as the whole list of what a player sees and a missing line
    -- always means somebody forgot.
    ["COLLAGE"] = "COLLAGE",
    -- PEGADOS carries the two halves the English needs a clause for: stuck to
    -- something, and stuck in the sense of not going anywhere. The verb is the
    -- gluestick's own line's -- SUJETA / PEGA -- so a player who finished it is
    -- reading a word they know. 50 characters against the longest card at 58.
    ["THEY GO WITH THE HALF YOU CUT, AND STAY STUCK"] =
        "SE VAN CON LA MITAD QUE CORTAS Y SE QUEDAN PEGADOS",
    -- CHAMUSCON is what a page looks like after a flame has been across it, which
    -- is the row: not burnt through, scorched. Nine characters, and it keeps the
    -- marker family's habit of naming the *mark* rather than the tool (MECHA, and
    -- the RASPON one pair over).
    ["SCORCH"] = "CHAMUSCON",
    ["THE BLADES LEAVE THEM BURNING AS THEY GO"] =
        "LAS CUCHILLAS LOS DEJAN ARDIENDO AL PASAR",
    -- CIZALLA is the shears a print shop cuts paper with and the word for shearing
    -- -- one half of a thing sliding past the other -- which is exactly the pair:
    -- the cut says where the line is and the rub drives them across it. Seven
    -- characters, and it is the same double meaning the English name carries.
    --
    -- The unlock keeps TOCA and DESLIZA, the pairing the STUB, the SCUFF and the
    -- SNAG all use: the same two gestures told apart the same way should be told
    -- apart in the same words wherever they turn up.
    ["SHEAR"] = "CIZALLA",
    ["TAP TO CUT THE PAGE, SWIPE THEM OVER THE EDGE"] =
        "TOCA PARA CORTAR, DESLIZA PARA ECHARLOS AL BORDE",
    -- **RAYA is the best name in the table and it is not a translation, it is the
    -- same idiom arriving in the other language.** DEADLINE is a line drawn in ink
    -- that must not be crossed -- a printer's word before it was an office one --
    -- and *pasarse de la raya* is the sentence every Spanish speaker already has for
    -- exactly that. Four characters, the shortest name on the strip, against
    -- PERFORADORA's eleven.
    --
    -- Which is why the card says RAYA twice: the name and the thing it does are one
    -- word, so the card can afford to lean on it, and a player who reads the card
    -- has been told what the tool is called and what it does in the same breath. 39
    -- characters against the longest card in the book at 58.
    ["DEADLINE"] = "RAYA",
    ["NOTHING CROSSES THE LINE, AND IT STAYS DRAWN"] =
        "NADIE CRUZA LA RAYA, Y LA RAYA SE QUEDA",
    -- The library's own demand, filled with the names of the lines a fusion is
    -- made of. Translated before the slot is filled and the names translated on
    -- the way in, exactly as the collection's demands are (src/library.lua).
    ["FINISH %s FIRST"] = "TERMINA ANTES %s",

    ["A PENCIL. IT SCRATCHES WHATEVER YOU DRAW OVER"] =
        "UN LAPIZ. RAYA TODO LO QUE DIBUJAS ENCIMA",
    ["IT SCRATCHES DEEPER"] = "RAYA MAS HONDO",
    ["A BROADER POINT, PRESSED HARDER"] = "PUNTA MAS ANCHA Y MAS APRETADA",
    ["THE LONGER THE LINE, THE LESS EACH PIXEL COSTS"] =
        "CUANTO MAS LARGA LA LINEA MENOS CUESTA CADA PIXEL",
    ["CLOSE THE LINE IN A LOOP: EVERYTHING INSIDE IS CUT"] =
        "CIERRA LA LINEA EN UN LAZO: TODO LO DE DENTRO SE CORTA",

    ["A PEN. ITS LINE IS A WALL THEY CANNOT CROSS"] =
        "UN BOLIGRAFO. SU LINEA ES UN MURO QUE NO CRUZAN",
    ["A BROADER NIB LAYS A THICKER WALL"] =
        "UNA PUNTA MAS ANCHA LEVANTA UN MURO MAS GRUESO",
    ["THE LINE STINGS WHATEVER LEANS ON IT"] =
        "LA LINEA PICA A TODO LO QUE SE APOYA EN ELLA",
    ["WHEN THE LINE GOES IT TAKES THE CROWD WITH IT"] =
        "CUANDO LA LINEA SE VA SE LLEVA A LA MULTITUD",
    ["THE LAST LINE STAYS UNTIL YOU DRAW ANOTHER"] =
        "LA ULTIMA LINEA SE QUEDA HASTA QUE DIBUJES OTRA",

    ["A RUBBER. IT SHOVES WHAT IT RUBS AT, HARD"] =
        "UNA GOMA. EMPUJA FUERTE LO QUE BORRA",
    ["THE SHOVE THROWS THEM FURTHER"] = "EL EMPUJON LOS MANDA MAS LEJOS",
    ["NO SCRUB NEEDED: LEAN IT ON THEM AND IT SHOVES"] =
        "SIN FROTAR: APOYALA ENCIMA Y EMPUJA",
    ["SCRUBBING THE SAME PATCH COSTS HALF THE INK"] =
        "FROTAR EL MISMO SITIO CUESTA LA MITAD DE TINTA",
    ["WHAT IT SENDS FLYING KNOCKS DOWN WHAT IT HITS"] =
        "LO QUE MANDA VOLANDO TIRA A LO QUE GOLPEA",

    ["A HIGHLIGHTER. WHAT IT COVERS KEEPS BURNING"] =
        "UN SUBRAYADOR. LO QUE CUBRE SIGUE ARDIENDO",
    ["A WIDER BAND COMES OFF THE NIB"] = "SALE UNA BANDA MAS ANCHA DE LA PUNTA",
    ["IT BURNS DEEPER"] = "QUEMA MAS HONDO",
    ["LAYERS STACK WHERE YOU DRAW OVER YOUR OWN INK"] =
        "LAS CAPAS SE SUMAN DONDE PINTAS SOBRE TU TINTA",
    ["WHAT TOUCHES THE BAND CATCHES FIRE"] = "LO QUE TOCA LA BANDA SE PRENDE",

    ["A GLUESTICK. WHATEVER IT SMEARS STOPS DEAD"] =
        "UN PEGAMENTO. LO QUE UNTA SE QUEDA CLAVADO",
    ["A WIDER SMEAR COMES OFF THE STICK"] = "SALE UNA MANCHA MAS ANCHA DE LA BARRA",
    ["WHAT IT HOLDS TAKES DEEPER CUTS"] = "LO QUE SUJETA RECIBE CORTES MAS HONDOS",
    ["WHAT COMES LOOSE COMES AWAY TORN"] = "LO QUE SE SUELTA SE SUELTA ROTO",
    ["THE SMEAR PULLS EVERYTHING NEAR IT IN"] = "LA MANCHA ATRAE TODO LO QUE PASA CERCA",

    ["A PUSHPIN. TAP AND IT PUNCHES A HOLE IN THEM"] =
        "UNA CHINCHETA. TOCA Y LES ABRE UN AGUJERO",
    ["IT PINS THEM DOWN FOR LONGER"] = "LOS CLAVA MAS TIEMPO",
    ["A WIDER CIRCLE COMES DOWN"] = "BAJA UN CIRCULO MAS ANCHO",
    ["THE POINT BITES DOUBLE WHAT IT FALLS ON"] = "LA PUNTA MUERDE EL DOBLE AL CAER",
    ["WHAT THE CRATER KILLS DRIVES THE POINT DEEPER"] =
        "LO QUE MATA EL CRATER CLAVA LA PUNTA MAS HONDO",

    ["A STAPLER. TAP AND IT FASTENS ONE TO THE PAGE"] =
        "UNA GRAPADORA. TOCA Y GRAPA UNO A LA HOJA",
    ["IT DRIVES IN DEEPER"] = "SE CLAVA MAS HONDO",
    ["ONE IN FIVE GOES STRAIGHT THROUGH"] =
        "UNA DE CADA CINCO ATRAVIESA DEL TODO",
    ["IT TEARS BACK OUT AND BITES AGAIN"] =
        "SE ARRANCA DE LA HOJA Y VUELVE A MORDER",
    ["HOLD AND DRAG TO RUN A SEAM OF THEM"] =
        "MANTEN Y ARRASTRA PARA COSER UNA FILA",

    ["SCISSORS"] = "TIJERAS",
    ["SCISSORS. TAP TWICE AND THE PAGE CUTS BETWEEN"] =
        "TIJERAS. TOCA DOS VECES Y LA HOJA SE CORTA ENTRE",
    ["THE CUT RUNS AS FAR AS THE SECOND TAP"] =
        "EL CORTE LLEGA HASTA EL SEGUNDO TOQUE",
    ["IT BITES DEEPER AND WIDER BETWEEN YOUR TAPS"] =
        "MUERDE MAS HONDO Y MAS ANCHO ENTRE TUS TOQUES",
    ["IT RUNS ON PAST BOTH TAPS TO THE EDGES"] =
        "SIGUE MAS ALLA DE LOS DOS TOQUES HASTA LOS BORDES",
    -- The finale takes the crowd with the paper rather than leaving it to wither
    -- there, so the line says so in both languages: "se va" and "y ellos con
    -- ella" are the half of the page leaving and the crowd leaving with it, and
    -- the feminine agreement is the mitad's. 46 characters against the English's
    -- 49 and the longest card in the book at 58, so the strip holds it either way.
    ["THE HALF YOU ARE NOT ON GOES, AND THEY GO WITH IT"] =
        "LA MITAD DONDE NO ESTAS SE VA, Y ELLOS CON ELLA",

    ["A COMPASS. IT CUTS A CIRCLE ROUND THEM"] =
        "UN COMPAS. CORTA UN CIRCULO A SU ALREDEDOR",
    ["IT OPENS OUT WIDER"] = "SE ABRE MAS",
    ["THE LEAD BITES DOUBLE WHERE IT SETS OFF"] =
        "LA MINA MUERDE EL DOBLE DONDE ARRANCA",
    ["TWICE ROUND, AND IT CUTS FAR DEEPER"] = "DOS VUELTAS Y CORTA MUCHO MAS HONDO",
    ["A SECOND LEG COMES ROUND THE OTHER WAY"] = "UNA SEGUNDA PATA VA AL OTRO LADO",

    ["A RULER. IT COMES DOWN AND CLEARS A LANE"] =
        "UNA REGLA. BAJA Y DESPEJA UN CARRIL",
    ["A WIDER BAND COMES DOWN"] = "BAJA UNA BANDA MAS ANCHA",
    ["IT COMES DOWN HARDER"] = "BAJA MAS FUERTE",
    ["LONGER AND WIDER AGAIN"] = "MAS LARGA Y MAS ANCHA OTRA VEZ",
    ["IT RULES THE WHOLE PAGE END TO END"] = "RAYA LA HOJA ENTERA DE PUNTA A PUNTA",

    --- the catalogue: the endless lines ------------------------------------

    -- A line's *name* is the one string in the catalogue drawn into a width that
    -- is written down rather than measured: the draft card at its narrowest
    -- (`CARD_MIN_W` in src/levelup.lua) leaves 53 pixels for it beside the icon.
    -- Everything else -- every level's text on a card, every name on the
    -- library's shelf -- is either wrapped or measured off the widest in the
    -- book, so it takes the room it needs. These are cut to that 53 instead.

    ["PRESS HARDER"] = "APRIETA MAS",
    ["EVERYTHING YOU DO CUTS DEEPER"] = "TODO LO QUE HACES CORTA MAS HONDO",
    ["DEEPER AGAIN. THERE IS NO LAST ONE"] = "MAS HONDO OTRA VEZ. NO HAY ULTIMA",

    ["MORE PAGE"] = "MAS HOJA",
    ["+15 MAX HEALTH AND +15 BACK NOW"] = "+15 DE VIDA MAXIMA Y +15 YA",
    ["+15 MORE, AND +15 BACK NOW"] = "+15 MAS Y +15 YA",

    ["FASTER STILL"] = "MAS RAPIDO",
    ["FASTER AGAIN. THERE IS NO LAST ONE"] = "MAS RAPIDO OTRA VEZ. NO HAY ULTIMA",

    ["SWEEP UP"] = "RECOGER",
    ["XP COMES FROM FURTHER AND IS WORTH MORE"] =
        "LA XP LLEGA DE MAS LEJOS Y VALE MAS",
    ["FURTHER AND MORE AGAIN"] = "MAS LEJOS Y MAS VALOR OTRA VEZ",

    ["TOP UP"] = "RELLENAR",
    ["A DEEPER WELL THAT FILLS FASTER"] = "UN TINTERO MAS HONDO QUE LLENA MAS RAPIDO",
    ["DEEPER AND FASTER AGAIN"] = "MAS HONDO Y MAS RAPIDO OTRA VEZ",

    ["PATCH UP"] = "REMENDAR",
    ["YOU MEND A LITTLE FASTER"] = "TE REMIENDAS UN POCO MAS RAPIDO",
    ["A LITTLE FASTER AGAIN"] = "UN POCO MAS RAPIDO OTRA VEZ",

    ["STAYS LONGER"] = "DURA MAS",
    ["EVERYTHING YOU LEAVE LASTS AND HOLDS LONGER"] =
        "TODO LO QUE DEJAS DURA Y SUJETA MAS",
    ["LONGER AGAIN. THERE IS NO LAST ONE"] = "MAS OTRA VEZ. NO HAY ULTIMA",

}

local DICT = { es = ES }

--- lookup --------------------------------------------------------------------

-- The one door every string goes through on its way to the page. English is the
-- key, so English needs no table and a string with no translation yet comes back
-- as itself -- which is the whole reason for keying this way: a gap in the
-- Spanish reads as English copy rather than as a missing-key marker.
--
-- Safe with nil, so a caller drawing something optional (a design's hint, a
-- record that is not there yet) does not have to ask first.
function I18n.t(text)
    if not text then return text end
    local dict = DICT[I18n.lang]
    return (dict and dict[text]) or text
end

-- A phrase from the collection (src/collection.lua), put into words: the key
-- translated first and the slots filled afterwards, since a line built before the
-- lookup is a line looked up under words no dictionary has -- `BEAT 3 LESSONS` is
-- not a key and `BEAT %d LESSONS` is. A string in a slot is itself a key: a
-- lesson's name is a word and a number is not.
--
-- Two slots, because a fusion names both the lines it is made of. Neither is
-- required and the second is never filled without the first, so a phrase with one
-- slot passes exactly the one argument `format` is expecting.
--
-- A clock -- `9:00` -- goes in as a string and comes back out of `I18n.t`
-- unchanged, which is that function's documented answer for anything it has no
-- entry for. That is the right answer rather than a near miss: digits are digits
-- in every language, and a dictionary that had an entry for every clock face would
-- be a dictionary of numbers.
--
-- It lives here rather than on the screens that draw one because there are three
-- of those now -- the library's holes, the timetable's shut pages and the homework
-- list -- and the rule it enforces is a rule about translation rather than about
-- any of them. Safe with nil like `I18n.t`, so a gate with only half a sentence to
-- say draws the half.
function I18n.say(p)
    if not p then return nil end

    local text = I18n.t(p.key)
    if p.a == nil then return text end

    local a = type(p.a) == "string" and I18n.t(p.a) or p.a
    if p.b == nil then return text:format(a) end

    return text:format(a, type(p.b) == "string" and I18n.t(p.b) or p.b)
end

--- which language ------------------------------------------------------------

function I18n.index()
    for i, lang in ipairs(I18n.langs) do
        if lang.key == I18n.lang then return i end
    end
    return 1
end

function I18n.current()
    return I18n.langs[I18n.index()]
end

-- A key the game no longer has a language for -- an options file written by a
-- later version, or edited by hand -- leaves the language where it was rather
-- than putting the game into one it cannot draw.
function I18n.set(key)
    for _, lang in ipairs(I18n.langs) do
        if lang.key == key then
            I18n.lang = key
            return true
        end
    end
    return false
end

-- The next language round, which is what the title screen's corner button and
-- the settings page's arrows both do. Two languages make it a toggle; it is
-- written as a step so a third costs neither of them anything.
function I18n.step(dir)
    local n = #I18n.langs
    I18n.lang = I18n.langs[(I18n.index() - 1 + (dir or 1)) % n + 1].key
end

return I18n
