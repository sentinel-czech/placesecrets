**SPECIFIKACE DIFF #3**

Web -- Administrace a uživatelské rozhraní

Verze 1.0 \| 9. 3. 2026

**1 Správa měst -- mapa s clusteringem**

Nad výpisem měst v admin sekci přibyde interaktivní mapa zobrazující
všechna města v databázi. Mapa slouží jako vizuální orientační vrstva a
zároveň jako rychlý vstup do detailu daného města.

**1.1 Mapová komponenta**

  --------------------- -------------------------------------------------
  **Knihovna**          Leaflet.js (nebo Mapbox GL JS -- dle stávajícího
                        výběru projektu)

  **Výchozí zoom**      Automatické \"fit bounds\" na všechna dostupná
                        města po načtení

  **Clustering**        Leaflet.markercluster / Supercluster --
                        shlukování markerů při oddálení

  **Marker**            Každé město = jeden pin; barva/ikona odlišena dle
                        stavu (aktivní / neaktivní)

  **Cluster badge**     Číslo uvnitř clusteru = počet měst ve shluku;
                        klikem na cluster se mapa přiblíží
  --------------------- -------------------------------------------------

**1.2 Interakce**

-   Zoom: kolečko myši, pinch-to-zoom (touch), tlačítka +/-- na mapě

-   Klik na jednotlivý marker → otevře stejný detail/edit formulář města
    jako tlačítko \"Edit\" v tabulce

-   Hover na marker → tooltip se jménem města a počtem míst

-   Mapa a tabulka níže jsou synchronizovány -- filtr v tabulce přebarví
    / skryje markery

**1.3 Layout**

-   Mapa má fixní výšku 360 px, šířka 100 % kontejneru

-   Nad mapou: nadpis sekce + tlačítko \"Přidat město\"

-   Pod mapou: stávající tabulka měst (beze změny struktury)

> *📌 Mapa se renderuje pouze na admin routě /admin/cities. Na mobilních
> zařízeních s šířkou \< 640 px se mapa skryje (accordion \"Zobrazit
> mapu\").*

**2 Filtrování typů míst dle aktivního jazyka**

Seznam typů míst (Place Types) v administraci zobrazuje pro každý záznam
název pouze v aktuálně zvoleném jazyce rozhraní.

**2.1 Filtr / přepínač jazyka**

  --------------------- -------------------------------------------------
  **Umístění**          Panel nad tabulkou typů míst

  **Komponenta**        Segment / pill přepínač se zkratkami jazyků (EN
                        \| CZ \| DE \| ...)

  **Výchozí stav**      Jazyk převzat ze stávajícího nastavení admin UI

  **Perzistence**       Vybraný jazyk uložen do localStorage (klíč:
                        adminLangFilter)
  --------------------- -------------------------------------------------

**2.2 Chování tabulky**

-   Sloupec \"Název\" zobrazuje překlad pro aktivní jazyk; pokud překlad
    neexistuje, zobrazí se fallback v EN + ikonka ⚠️

-   Ostatní sloupce (ID, slug, ikona, akce) zůstávají beze změny

-   Inline editace překladu přímo v buňce -- klik → input → Enter/blur
    uloží

> *📌 Filtr jazyků v sekci typů míst je nezávislý na globálním jazykovém
> nastavení uživatele.*

**3 Správa uživatelů -- servisní tlačítka**

**3.1 Přehled nových akcí**

Na stránce detailu uživatele (i v tabulkovém přehledu jako kontextové
menu) přibydou tři servisní akce:

  --------------------- -------------------------------------------------
  **GDPR export**       Stažení ZIP s daty profilu (bez aktivitních /
                        analytických dat)

  **Deaktivace účtu**   Zamknutí účtu bez smazání -- uživatel se nemůže
                        přihlásit

  **Zpět na seznam**    Navigační tlačítko z detailu profilu zpět na
                        /admin/users
  --------------------- -------------------------------------------------

**3.2 GDPR export (ZIP)**

-   Akce: POST /api/admin/users/{id}/gdpr-export

-   Obsah ZIP archivu:

    -   profile.json -- jméno, e-mail, datum registrace, nastavení
        jazyka, subscription tier

    -   settings.json -- uživatelské preference, notifikace

    -   NEZAHRNOVAT: navštívená místa, aktivitní logy, analytická data,
        platební záznamy (pouze GDPR-profilová data)

-   Název souboru: gdpr_export\_{userId}\_{YYYYMMDD}.zip

-   V UI: tlačítko \"GDPR Export\" s ikonou stahování; po kliknutí
    spinner → automatické stažení

**3.3 Deaktivace / zamknutí účtu**

  --------------------- -------------------------------------------------
  **Stav v DB**         Nové pole users.status: enum(\'active\',
                        \'deactivated\') DEFAULT \'active\'

  **Dopad**             Přihlášení zamítnuto (HTTP 403 s kódem
                        ACCOUNT_DEACTIVATED); existující session ukončena

  **Reverzibilita**     Admin může účet znovu aktivovat tlačítkem
                        \"Aktivovat\"

  **Smazání vs          Deaktivace NEMAŽE žádná data -- plně reverzibilní
  deaktivace**          operace

  **UI stav**           Deaktivovaný uživatel zobrazen s červeným badge
                        \"Deaktivován\" v tabulce
  --------------------- -------------------------------------------------

-   Tlačítko \"Deaktivovat\" → confirm dialog: \"Opravdu chcete
    deaktivovat účet {email}? Uživatel se nebude moci přihlásit.\"

-   Po potvrzení: PATCH /api/admin/users/{id}/status body: {status:
    \'deactivated\'}

**3.4 Navigace zpět na seznam profilů**

-   Na stránce detailu uživatele přibyde tlačítko \"← Zpět na seznam
    uživatelů\" vlevo nahoře

-   Klik → navigate(-1) nebo pevná routeURL /admin/users (dle
    implementace routeru)

**4 Síň slávy -- výběr kontextu**

Stránka Síně slávy dostane přepínatelný \"kontext\": celosvětový přehled
(Overall) nebo přehled filtrovaný na konkrétní město / místo.

**4.1 Přepínač kontextu**

  --------------------- -------------------------------------------------
  **Umístění**          Horní část stránky Síně slávy, před samotným
                        žebříčkem

  **Výchozí stav**      Overall (všechna data)

  **Možnosti výběru**   Overall \| Vybrat město \| Vybrat místo
  --------------------- -------------------------------------------------

**4.2 Výběr města**

-   Dropdown / combobox se search -- seznam aktivních měst ze
    /api/cities

-   Po výběru se žebříček přepočítá a zobrazí pouze návštěvy míst v
    daném městě

**4.3 Výběr konkrétního místa**

-   Druhý dropdown aktivní po výběru města, nebo jako samostatný search

-   Výběr konkrétního místa zobrazí síň slávy pro toto jedno místo

**4.4 URL stav**

-   Filtr reflektován v query parametrech: /admin/hall-of-fame?city=42
    nebo ?place=123

-   Přímý odkaz / refresh zachová výběr

> *📌 Komponenta Síně slávy neřeší samotnou logiku výpočtu pořadí --
> pouze předává filtrační parametry existujícímu endpointu.*

**5 Tlačítko \"Opustit administraci\"**

V hlavním admin navigačním panelu (sidebar nebo topbar) přibyde trvalé
tlačítko pro návrat do veřejného webu.

  --------------------- -------------------------------------------------
  **Label**             \"← Zpět na web\" nebo \"Opustit administraci\"

  **Ikona**             ExternalLink nebo ArrowLeft (Lucide)

  **Cíl**               Kořenová URL veřejného webu: / (nebo
                        konfigurovatelná VITE_PUBLIC_URL)

  **Chování**           Otevření v aktuální záložce; žádný confirm dialog

  **Umístění**          Spodní část sidebaru, nebo pravý konec topbaru --
                        vizuálně odděleno od admin navigace

  **Styling**           Odlišný styl (ghost / outlined, jiná barva) aby
                        bylo jasné, že opouštíme admin
  --------------------- -------------------------------------------------

**6 Dashboard uživatele**

**6.1 Záložka \"Statistiky\" -- navštívená místa**

Tato záložka obsahuje personalizovanou mapu a filtrační nástroje nad
daty navštívených míst přihlášeného uživatele.

**6.1.1 Mapa navštívených míst**

  --------------------- -------------------------------------------------
  **Typ**               Interaktivní mapa (Leaflet / Mapbox) s body
                        navštívených míst

  **Markery**           Každé navštívené místo = pin; barva podle typu
                        památky

  **Časové rozsahy**    Overall time \| Posledních 30 dní \| Vybrané
                        období (date range picker)

  **Filtry typů**       Checkboxy / multi-select pro typy míst (kostel,
                        hrad, muzeum ...)

  **Tooltip**           Hover na pin → název místa + datum návštěvy

  **Klik na pin**       Otevře detail místa (readonly, bez přehrávání
                        audia)
  --------------------- -------------------------------------------------

**6.1.2 Export dat**

-   Tlačítko \"Exportovat\" s výběrem formátu:

    -   CSV -- tabulkový přehled (místo, GPS, datum, typ)

    -   JSON -- strojově čitelný formát pro další zpracování

    -   PDF -- přehledová sestava s miniaturní mapkou a tabulkou

-   Export respektuje aktuálně nastavené filtry (časové období + typy)

-   API endpoint: GET
    /api/user/visits/export?format=csv&from=...&to=...&types=...

**6.2 Záložka \"Explore\"**

  --------------------- -------------------------------------------------
  **Podmínka            Prohlížeč musí poskytnout GPS (Geolocation API)
  zobrazení**           

  **Výchozí zoom**      Oblast cca 10 km okolo aktuální polohy uživatele

  **Markery**           Místa z databáze v daném okruhu; barevně
                        rozlišená dle typu

  **Filtr typů**        Stejný multi-select jako v sekci Statistiky

  **Klik na marker**    Detail místa: název, popis, fotogalerie, základní
                        info -- BEZ přehrávání audia

  **Fallback (bez       Informativní hláška s tlačítkem \"Povolit
  GPS)**                polohu\"
  --------------------- -------------------------------------------------

> *📌 Audio průvodce je dostupný pouze v mobilní aplikaci. Na webu se
> audio netýká ani detailu místa z Explore ani ze Statistik.*

**7 Nastavení jazyka v profilu uživatele**

Stránka Account Settings (profil uživatele) chybí sekci Language
Settings. Přidáme ji jako samostatný blok.

**7.1 Nová sekce \"Language Settings\"**

  --------------------- -------------------------------------------------
  **Umístění na         Pod sekcí Account Settings, nad sekcí
  stránce**             Notifications (pokud existuje)

  **Komponenta výběru** Select / dropdown se vlajkami zemí + názvem
                        jazyka v nativním písmu

  **Dostupné jazyky**   EN, CZ, SK, DE, ES, FR, PT, RU, VN, CN, KR

  **Uložení**           PATCH /api/user/profile body: {language: \'cs\'}
                        -- okamžité použití bez reloadu

  **Projev**            Celý web / app se přepne do zvoleného jazyka;
                        hodnota uložena v DB i localStorage

  **Výchozí**           Detekce z Accept-Language hlavičky prohlížeče při
                        první registraci
  --------------------- -------------------------------------------------

**7.2 Lokalizační kódy**

  --------------------- -------------------------------------------------
  **EN**                en

  **CZ**                cs

  **SK**                sk

  **DE**                de

  **ES**                es

  **FR**                fr

  **PT**                pt

  **RU**                ru

  **VN**                vi

  **CN**                zh

  **KR**                ko
  --------------------- -------------------------------------------------

**8 Jazykové soubory -- specifikace a šablona**

Claude Code připraví jazykové soubory pro všechny jazyky uvedené v sekci
7. Níže je závazná struktura a seznam povinných klíčů.

**8.1 Přehled jazyků a souborů**

  ------------------------------------------------------------------------
  **Kód**   **Jazyk**              **Poznámka**
  --------- ---------------------- ---------------------------------------
  EN        English                Výchozí, existující základ

  CZ        Čeština                Nový soubor -- viz sekce 8

  SK        Slovenčina             Nový soubor -- viz sekce 8

  DE        Deutsch                Nový soubor -- viz sekce 8

  ES        Español                Nový soubor -- viz sekce 8

  FR        Français               Nový soubor -- viz sekce 8

  PT        Português              Nový soubor -- viz sekce 8

  RU        Русский                Nový soubor -- viz sekce 8

  VN        Tiếng Việt             Nový soubor -- viz sekce 8

  CN        中文 (简体)            Nový soubor -- viz sekce 8

  KR        한국어                 Nový soubor -- viz sekce 8
  ------------------------------------------------------------------------

**8.2 Souborová struktura**

-   Umístění: src/locales/{lang}/translation.json

-   Formát: JSON, UTF-8, bez BOM

-   Klíče: camelCase, hierarchicky zanořené do namespace objektů

-   Příklad cesty: common.save, admin.cities.title,
    user.dashboard.explore.noGps

**8.3 Povinné namespace a klíče**

**common -- sdílené akce a stavy**

-   save, cancel, delete, edit, add, back, close, loading, error,
    success, noData

-   confirm, confirmDelete, export, filter, search, reset, language

**nav -- navigace**

-   admin, cities, placeTypes, users, hallOfFame, dashboard, profile,
    settings

-   leaveAdmin, backToWeb

**admin.cities -- sekce měst**

-   title, mapHint, addCity, editCity, markerTooltip (název + počet
    míst)

**admin.placeTypes -- typy míst**

-   title, languageFilter, missingTranslation, inlineEditHint

**admin.users -- správa uživatelů**

-   title, gdprExport, gdprExportDesc, deactivate, activate,
    deactivateConfirm

-   statusActive, statusDeactivated, backToList

**admin.hallOfFame -- síň slávy**

-   title, contextOverall, selectCity, selectPlace, noData

**user.dashboard -- dashboard uživatele**

-   statsTab, exploreTab

-   stats.title, stats.filterTypes, stats.filterPeriod, stats.exportBtn

-   stats.exportFormats (csv, json, pdf)

-   explore.title, explore.noGps, explore.enableGps, explore.placeDetail

**user.profile -- profil a nastavení**

-   accountSettings, languageSettings, selectLanguage, languageSaved

**8.4 Příklad souboru EN (referenční šablona)**

Níže je zkrácený příklad struktury (Claude Code rozepíše kompletní
soubory pro všechny jazyky):

{ \"common\": { \"save\": \"Save\", \"cancel\": \"Cancel\", \... },
\"nav\": { \"leaveAdmin\": \"← Back to website\", \... }, \"admin\": {
\"cities\": { \"title\": \"Cities\", \"mapHint\": \"Click a pin to
edit\" }, \"users\": { \"gdprExport\": \"GDPR Export\", \"deactivate\":
\"Deactivate account\" }, \"hallOfFame\": { \"contextOverall\":
\"Overall\", \"selectCity\": \"Select city\" } }, \"user\": {
\"dashboard\": { \"exploreTab\": \"Explore\", \"explore\": { \"noGps\":
\"Enable location to explore nearby places\" } }, \"profile\": {
\"languageSettings\": \"Language settings\", \"selectLanguage\":
\"Interface language\" } } }

> *📌 Claude Code musí zajistit, že všechny klíče jsou přítomny ve VŠECH
> jazykových souborech. Chybějící klíč = fallback na EN, ale nesmí
> způsobit runtime chybu.*

**9 Implementační pokyny pro Claude Code**

**9.1 Pořadí implementace (doporučené)**

-   Sekce 7: Language Settings v profilu + napojení i18n na existující
    systém

-   Sekce 8: Vygenerovat všechny jazykové soubory (EN jako základ,
    ostatní přeložit)

-   Sekce 5: Tlačítko \"Opustit administraci\" -- nejjednodušší, rychlá
    win

-   Sekce 2: Filtr jazyků u typů míst

-   Sekce 3: Servisní tlačítka uživatelů (GDPR + deaktivace + zpět)

-   Sekce 1: Mapa měst s clusteringem

-   Sekce 4: Síň slávy -- přepínač kontextu

-   Sekce 6: Dashboard -- statistiky a explore

**9.2 Technické závislosti**

  --------------------- -------------------------------------------------
  **Mapová knihovna**   Leaflet + leaflet.markercluster (již instalovat
                        pokud chybí)

  **i18n**              Stávající řešení (i18next / react-i18next) --
                        rozšířit o nové jazyky

  **Export**            client-side: PapaParse (CSV), native JSON, jsPDF
                        (PDF) nebo serverový endpoint

  **Geolocation**       Nativní browser Geolocation API -- žádná
                        závislost
  --------------------- -------------------------------------------------

**9.3 Databázové změny**

-   users: přidat sloupec status ENUM(\'active\',\'deactivated\') NOT
    NULL DEFAULT \'active\'

-   users: přidat sloupec language VARCHAR(5) DEFAULT \'en\'

-   Migrace: ALTER TABLE nebo ORM migration file -- dle stávající
    strategie projektu

**9.4 API endpointy -- souhrn**

  ------------------------------------- -------------------------------------------------
  **POST                                Vrátí ZIP stream s GDPR daty profilu
  /api/admin/users/{id}/gdpr-export**   

  **PATCH                               Body: {status: \'active\'\|\'deactivated\'}
  /api/admin/users/{id}/status**        

  **GET /api/user/visits/export**       Query: format, from, to, types -- export návštěv

  **PATCH /api/user/profile**           Body: {language: \'cs\'} -- uložení jazyka
  ------------------------------------- -------------------------------------------------

*--- Konec specifikace Diff #3 ---*
