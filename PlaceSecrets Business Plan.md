<!-- Export z Business Plan Review.dc.html · 23. 10. 2026 · interaktivní kalkulačky jsou ve výchozím nastavení -->

- Interní dokument · Business plán & review
- 18. 10. 2026 · revize 3 · sjednocený cílový stav

# Audioprůvodce pro cestovatele a rodiny, který tvoří komunita

Na místě začne mluvit příběh, který namluvil skutečný člověk. Jedno audio denně je zdarma, další se odemkne za cenu kafe, celé město za cenu oběda. Autoři kvalitního obsahu dostávají kredity, kterými si sami odemykají audio. Instituce (muzea, zoo, zahrady) přijdou později.

---

Hlavní čísla

146 tis. € – 224 tis. €

čistý roční příjem, pokud si **každý 1 000. návštěvník** pilotních českých míst, Říma a 6 dalších doporučených měst koupí vstup do města za 6,50 €.

Jen česká místa: 22 tis. € – 36 tis. €. Výpočet a předpoklady najdete v kapitole 3.

1. **Řím vydělá víc než všechna česká místa dohromady**, ale i Praha sama stačí na rozjezd. Česko je pilot, Řím první zahraniční trh.
2. **„Cena oběda“ za město odpovídá trhu.** Komunitní trasa po Vatikánu stojí na VoiceMap 8–12 €.
3. **„Kafe“ by mělo stát aspoň 1,99 €.** Z platby 1 USD kartou vezmou poplatky ~38 %.
4. **Kredity místo hotovosti** odpadne výplatní agenda. Kredity ale musí dostávat jen kvalitní obsah a nesmí nahradit placení.
5. **Lidský hlas nás odliší.** Pražský konkurent SmartGuide prodává AI hlas a strojový překlad.

---

*Kapitola 0 · cílový stav*

## Jak PlaceSecrets stavíme

Jedna sada rozhodnutí pro produkt, business i techniku. Platí pro aplikaci, web i admin a odpovídá implementačnímu promptu PlaceSecrets-remediation-prompt.md. U každého rozhodnutí je uvedeno, proč je lepší než alternativa.

- PlaceSecrets — jeden název; ID cz.tuma.placesecrets pro iOS i Android; placesecrets.app
- 1 / den — bezplatné audio, potom Kafe 1,99 € · Pivo 2,99 € · Město 4,99–7,99 €
- IAP — v aplikaci jen nákup přes App Store a Google Play; Comgate a Stripe na webu
- 0 peněz — autorům se nevyplácí; odměnou jsou kredity za ověřenou kvalitu

0.1

### Identita

PS-P0.4

| Jak to děláme | Proč takhle |
|---|---|
| **Název:** PlaceSecrets všude: aplikace, web, admin (placesecrets.app/admin), doklady PS-, deep link placesecrets://. | Jedna značka pro obchody, doménu i ochrannou známku. Bundle ID po zveřejnění nejde změnit. |
| **Provozovatel:** Údaje se načítají z konfigurace, nejsou natvrdo v kódu ani textech. | Právní texty se změní bez nové verze aplikace. |

0.2

### Produkt a ceny

PS-P1.1 · P1.2

| Jak to děláme | Proč takhle |
|---|---|
| **Zdarma:** 1 audio denně (kalendářní den, Praha). | Turista na 2–3denním výletu si nástroj vyzkouší víckrát, měsíční limit by ho odradil. |
| **Kafe 1,99 €:** 3 audia dle výběru, platnost 30 dní. | Impulzivní nákup u dalšího místa. Pod 1,99 € sežerou poplatky přes třetinu. |
| **Pivo 2,99 €:** celé jedno místo nebo trasa. | Mezistupeň mezi jedním audiem a celým městem. |
| **Oběd 4,99–7,99 €:** celé město na 30 dní včetně offline. Praha a Řím 7,99 €. | Odpovídá trhu (komunitní trasa po Vatikánu 8–12 €). Časové omezení zabrání sdílení a podpoří opakovaný nákup. |
| **Rodina 7,99 €, Celé Česko 12,99 €/rok:** město s dětskými verzemi; roční přístup ke všem lokalitám. | Rodiny jsou hlavní segment. Roční balíček je pro opakované výletníky. |
| **Konfigurace:** všechny ceny, limity a platnosti v tabulce app_config. | A/B test cen bez vydání nové verze. |

0.3

### Platby a nároky

PS-P0.2 · P0.3

| Jak to děláme | Proč takhle |
|---|---|
| **Aplikace:** výhradně In-App Purchase (StoreKit, Play Billing), obnovení nákupů na novém telefonu. | Jediná cesta, kterou Apple a Google u digitálního obsahu schválí. Uživatel platí jedním ťuknutím. |
| **Web:** stejné produkty přes Comgate a Stripe. Nárok je společný, takže nákup z webu funguje i v aplikaci. | Na webu odpadá provize obchodu a Comgate pokrývá české platby. |
| **Ověření:** nárok vzniká jen na serveru, z ověřené účtenky nebo webhooku. user_id se bere z přihlášení, nikdy z požadavku. | Nikdo si obsah neodemkne bez zaplacení. |
| **Revolut:** zrušen úplně. | Nešlo ho ověřit automaticky a ruční kontrola se neškáluje. |

0.4

### Obsah a hlas

PS-P1.5 · P2.4 · P2.5

| Jak to děláme | Proč takhle |
|---|---|
| **Placená sekce:** jen nahrávky skutečných lidí. | Lidský hlas je hlavní rozdíl proti konkurenci, která používá AI hlas. |
| **Strojový hlas:** jen u bezplatných textů, viditelně označený. Místo bez nahrávky se ukáže jako „Příběh se nahrává“. | Posluchač ví, za co platí. Admin z toho dostává seznam úkolů pro autory. |
| **Licence:** autor při nahrání udělí nevýhradní komerční licenci. Povinný zdroj textu, Wikipedie s uvedením autorů. | Obsah můžeme prodávat i institucím a nehrozí spor o práva. |
| **Moderace:** kurátor schvaluje před zveřejněním, nahlášení se řeší do 24 h, pietní místa vždy ručně. | Jeden nevhodný příběh na známém místě poškodí celou značku. |

0.5

### Kvalita, hodnocení a kredity

PS-P1.3 · P1.4

| Jak to děláme | Proč takhle |
|---|---|
| **Hodnocení:** jen přihlášený posluchač, který byl podle GPS na místě a poslechl aspoň 60 % nahrávky. Autor nehodnotí sám sebe. | Hodnocení nejde zfalšovat skriptem ani přáteli. |
| **Skóre:** jeden vzorec v celém systému: (v × R + m × C) ÷ (v + m), m = 20. Používá ho řazení, Hall of Fame i brána kvality. | Nová nahrávka se třemi 5★ nepředběhne ověřenou klasiku. |
| **Kredity:** neměnná účetní kniha, připisuje jen server jednou denně. +50 za bránu kvality, +3 za 10 poslechů, bonus za chybějící jazyk. Strop 300/měsíc, platnost 12 měsíců. | Odměna bez výplat, daní a KYC. Strop a kurz chrání tržby. |
| **Čerpání:** 30 kr. = 1 audio, 200 kr. = město. Nelze převést, nelze na vlastní obsah ani na instituce. | Kredity nenahradí placení. Varování v adminu nad 10 % odemčení kredity. |

0.6

### Bezpečnost

PS-P0.1

| Jak to děláme | Proč takhle |
|---|---|
| **Klíče:** web i aplikace používají jen veřejný klíč. Přístup řídí databázová pravidla (RLS) podle role. | Z prohlížeče nejde získat přístup k celé databázi. |
| **Admin operace:** přes serverové funkce s kontrolou role a platné PIN relace. Tajné klíče jen v Supabase Secrets. | I ukradený přihlašovací token nestačí na citlivé operace. |
| **Kontrola v CI:** build selže, pokud obsahuje tajný klíč nebo zakázaný vzor. | Chyba se nedostane do produkce omylem. |

0.7

### Poslech, mapy a offline

PS-P2.1–P2.3

| Jak to děláme | Proč takhle |
|---|---|
| **Spouštění:** poloměr 30–150 m na každém místě (výchozí 40 m). Při více místech najednou hraje nejbližší, ostatní jdou do fronty. Režim „jen se sluchátky“ je zapnutý. | V centru měst je bodů hustě, takže fronta zabrání chaosu. Sluchátka respektují pravidla památek. |
| **Záloha:** tlačítko „Jsem tady“ a seznam míst do 150 m. | GPS v úzkých uličkách a uvnitř budov selhává. |
| **Offline:** tlačítko „Stáhnout město“: audio, fotky a mapa. Po vypršení nároku se smaže. | Turisté v zahraničí šetří data a mají slabý signál. |
| **Mapy:** vlastní vektorové dlaždice (PMTiles) v úložišti, atribuce OSM. | Veřejný server OSM offline stahování nepovoluje. Vlastní dlaždice jsou levné a spolehlivé. |

0.8

### Jazyky

PS-P1.6 · P2.7

| Jak to děláme | Proč takhle |
|---|---|
| **Pořadí:** cs, en, de při spuštění, dále it, es, zh-Hant, ko, ja, fr, pl. | Řazeno podle vlivu na tržby (kap. 3). Němčina je v Praze největší zahraniční trh. |
| **Chybějící jazyk:** nabídne se angličtina se štítkem, strojový hlas ne. Autor první nahrávky v chybějícím jazyce dostane bonus. | Kvalita zůstane lidská a díry v jazycích se zaplní cíleně. |
| **UI aplikace:** všechny texty přes lokalizační soubory, kontrola parity v CI. | Německý posluchač nesmí narazit na české tlačítko. |

0.9

### Provoz a vydání

PS-P3.1–P3.4

| Jak to děláme | Proč takhle |
|---|---|
| **Prostředí:** staging a produkce zvlášť, nasazuje se nejdřív na staging. Zálohy s vyzkoušenou obnovou. | Platby a migrace se nikdy netestují na ostrých datech. |
| **Architektura:** Supabase (DB, přihlášení, úložiště, serverové funkce), Firebase (push, pády), Sentry, Resend, Netlify. Audio na Cloudflare R2, až přenos přesáhne 250 GB měsíčně. | Minimum vlastních serverů, platí se jen za to, co se používá. |
| **Geofencing:** buď licence Transistorsoft, nebo bezplatný nativní geofencing za stejným rozhraním. | Rozhodnutí je cenové. Kód je připravený na obě varianty. |
| **Před každým vydáním:** smoke test 7 kroků na iOS i Androidu (registrace → nákup → offline → geofence → push → hodnocení → kredity). | Ověří, že funguje celý tok peněz a obsahu, ne jen jednotlivé části. |

### Na čem stavíme (už funguje)

- Nativní geofencing na pozadí s registrací nejbližších 100 bodů. Hlavní slib produktu je technicky pokrytý.
- Poloměr spouštění na každém POI a vícejazyčné texty i audio v JSONB, takže jazyky z kap. 3 jdou přidávat bez migrace.
- Platební doklady (payment_receipts) s RLS, PDF a e-mailem. Splňuje to požadavek EU na doklad.
- GDPR: export a smazání účtu, audit log, cookie banner v 11 jazycích, soukromé fotky jen v zařízení.
- Role v adminu (superadmin / editor / viewer) a portál autorů s vlastními POI.
- Hall of Fame a portál autorů. Sjednotí se na jedno vážené skóre (kap. 0.5).
- CI s analýzou a testy, E2E Playwright, fail-fast konfigurace prostředí.

### Podmínky prvního vydání

|   |   |   |
|---|---|---|
| 1 | Web ani aplikace neobsahují tajný klíč; klíč je rotovaný | PS-P0.1 |
| 2 | Nákup v aplikaci jen přes IAP, testovací nákup v sandboxu projde | PS-P0.2 |
| 3 | Přístup vzniká jen z ověřené platby | PS-P0.3 |
| 4 | Jeden název a ID; doménové soubory pro deep linky nahrané | PS-P0.4 |
| 5 | Právní texty s údaji provozovatele, privacy URL | PS-P3.2 |
| 6 | Staging + Firebase + Sentry zapojené, zálohy ověřené | PS-P3.1 |
| 7 | Smoke test 7 kroků na iOS i Androidu | PS-P3.3 |

Kódy PS-… odkazují na úkoly v implementačním promptu.

---

*Kapitola 1*

## Produkt: nástroj pro cestovatele, obsah od komunity

Nejde o sociální síť. Nebudou žádné feedy ani diskuze k moderování. Komunitní je jen **zdroj obsahu**. Uživatel vidí jednoduchý nástroj: otevřít, poslouchat, jít dál. AI pomáhá v zákulisí (přepis, kontrola, návrh překladu), ale posluchač ji nikdy neslyší.

- Posluchač Rodina na výletě Tři tapy a poslouchá se. Krátké nahrávky (1–3 min), dětské verze, offline režim.
- Posluchač Zahraniční turista Praha a jeden výlet mimo ni. Jasný jazykový štítek, řazení podle hodnocení.
- Autor Místní nadšenec Spolky, studenti, průvodci. Odměnou jsou kredity a uznání. Stejný profil jako posluchač.
- Později Instituce Muzea, zoo, zahrady: oficiální kanál na stejné platformě.

### Konkurence

#### VoiceMap

Komunitní autoři · B2C

|   |   |
|---|---|
| Autoři | Standardně 50 % z prodeje po poplatcích, v destinacích bez obsahu dočasně 80 %. [↗](https://forum.voicemap.me/t/publish-in-key-destinations-or-attractions-and-earn-80-royalties/3661) |
| Kvalita | Každou trasu před zveřejněním schvaluje editor. [↗](https://voicemap.me/pricing) |
| Cena | Trasa po Vatikánu s GPS za 8–12 €. [↗](https://www.musa.guide/en/resources/best-audio-guide-vatican-museums) |

**Poučení:** Komunitní model funguje, ale stojí na kurátorovi. Náš rozdíl: autory odměňujeme kredity, ne hotovostí, takže odpadá výplatní agenda.

#### SmartGuide

Praha · B2B + AI

|   |   |
|---|---|
| Hlas | AI TTS jako levnější varianta, překlad přes DeepL. [↗](https://blog.smart-guide.org/en/smartguide-allows-guiding-tourists-better-with-ai-and-ar-enhancements-supported-by-1-million-grant) |
| Ceny | AI překlad 200 € za jazyk, 30+ jazyků. [↗](https://www.smartguide.app/tour-operators) |
| Peníze | Grant 1 mil. € od Evropské komise. [↗](https://blog.smart-guide.org/en/smartguide-allows-guiding-tourists-better-with-ai-and-ar-enhancements-supported-by-1-million-grant) |

**Poučení:** V technologii s nimi nesoupeřit. Odlišit se lidským hlasem, příběhem a rodinnými verzemi.

---

*Kapitola 2 · jádro dokumentu*

## Ceník a systém kreditů

Fungují dva oddělené okruhy. **Peníze** proudí jen od posluchačů k nám. **Kredity** proudí od nás k autorům a dají se utratit jen uvnitř aplikace. Autorům tak nic nevyplácíme a odměna je přesto skutečná.

### 2.1 Žebřík cen

- Každý den 0 € 1 audio zdarma Jedno libovolné audio denně. Ochutnávka, která přivede uživatele zpět. Akvizice; bez nákladů na obsah navíc
- Kafe 1,99 € Další 3 audia Okamžité odemčení, když posluchač stojí u dalšího místa. Čistý příjem ≈ 1,15 € v aplikaci
- Pivo 2,99 € Celé místo Všechny příběhy jedné památky nebo trasy (např. Sedlec). Čistý příjem ≈ 1,73 €
- Oběd 5–8 € Celé město Celá placená sekce lokality na 30 dní, včetně offline. Praha a Řím za 7,99 €, menší města za 4,99–5,99 €. Hlavní produkt; základ výpočtu v kap. 3

Ceny jsou návrh k A/B testu. „Kafe“ za 1,99 € místo 1 USD: platba kartou 3,4 % + 0,35 by z 1 USD vzala ~38 % ([VoiceMap docs](https://docs.voicemap.me/tour-publishers/tour-payment-calculations/)). V aplikaci zůstane z každého eura po DPH 21 % a 15% provizi obchodu ([Small Business Program](https://foliokit.io/blog/app-store-small-business-program)) zhruba 0,70 €.

### 2.2 Jak se kredity získávají

Jen za obsah, který prošel bránou kvality. Nahrání samo o sobě nic nepřináší.

|   |   |
|---|---|
| **Nahrávka projde branou kvality** Jednorázově, při ≥ 10 ověřených hodnoceních a skóre ≥ 4,3. | +50 kr. |
| **Ověřené poslechy** Za každých 10 poslechů na místě (GPS) nahrávky nad branou. | +3 kr. |
| **Nedostatkový obsah** Bonus za první kvalitní audio u místa nebo v jazyce, který chybí. | +30 kr. |
| **Měsíční strop** Ochrana proti farmení a ochrana kurzu. | max. 300 kr. |

Brána kvality

skóre = (v × R + m × C) ÷ (v + m) ≥ 4,3

v = počet ověřených hodnocení (posluchač byl podle GPS na místě a poslechl ≥ 60 % nahrávky), R = průměr nahrávky, C = průměr platformy, m = 20. Tři kamarádi s 5★ skóre téměř nezvednou. Teprve desítky skutečných posluchačů ano.

### 2.3 Kurz výhodný pro nás

Kredity mají pro autora hodnotu, pro nás ale skoro nic nestojí. Odemčení digitálního audia nemá žádné přímé náklady. Riziko je jen jedno: kredity nesmí nahradit nákupy.

|   |   |   |
|---|---|---|
| 30 kr. · = 1 audio (posluchač platí ≈ 0,66 €) | 200 kr. · = celé město (posluchač platí 5–8 €) | ≈ 0 € · přímé náklady pro nás na jedno odemčení |

|   |   |
|---|---|
| 1 | Kredity jen za obsah nad branou kvality. Nikdy za samotné nahrání. |
| 2 | Nelze je převést na peníze, poslat jinému účtu ani prodat. |
| 3 | Platnost 12 měsíců. Zůstatek se nehromadí do nekonečna. |
| 4 | Nelze jimi odemknout vlastní obsah a obsah institucí (fáze 3). |
| 5 | Při smazání nahrávky za porušení pravidel se kredity strhnou. |
| 6 | Kurz je záměrně „drahý“: na město potřebuje autor 4–7 kvalitních nahrávek. |

### 2.4 Příklad: jeden autor, jedna sezóna

Autor nahraje 6 příběhů v Kutné Hoře a 4 z nich projdou bránou kvality. Celkem mají 1 800 ověřených poslechů.

- Brána 4 nahrávky × 50 kr. 200 kr.
- Poslechy 1 800 ÷ 10 × 3 kr. 540 kr.
- Bonus 1× první příběh v němčině 30 kr.
- Celkem za sezónu (pod stropem) 770 kr.
- Hodnota ≈ 3 města nebo 25 audií ≈ 20 € pro autora

Autor si za to odemkne zhruba 3 celá města. Pro něj jde o odměnu v hodnotě ~20 €. Nás to stojí jen ušlý nákup, a to pouze v případě, že by si města jinak koupil.

### Spropitné zůstává zvlášť

Tlačítko „kup autorovi kafe“ vede na jeho vlastní odkaz (Revolut, Buy Me a Coffee). Peníze jdou mimo nás, takže nemáme výplaty ani hlášení.

### Daně a právo

Nepřevoditelné kredity bez hotovostní hodnoty jsou administrativně mnohem jednodušší než výplaty. I nepeněžní plnění však může být příjmem autora. Před spuštěním ověřit s daňovým poradcem. Podmínky kreditů (expirace, nepřevoditelnost) uvést v obchodních podmínkách.

### Hotovost později?

Výplaty v penězích jen pro úzkou skupinu top autorů a až ve chvíli, kdy tržby unesou KYC, poplatky za výplaty a účetnictví. U Stripe Connect stojí aktivní účet příjemce 2 € měsíčně plus poplatek za výplatu ([Stripe](https://stripe.com/connect/pricing)).

---

*Kapitola 3*

## Když koupí každý tisící

Návštěvnost pilotních českých míst, Říma a šesti dalších doporučených měst (Vídeň, Budapešť, Krakov, Barcelona, Florencie, Benátky) × podíl kupujících × cena vstupu do města. U každé lokality uvádíme **nízký** a **vysoký** odhad návštěvníků. Zdroje se liší v tom, co počítají: ubytované hosty, vstupy do památek, nebo všechny příchozí. Čistý příjem = 70 % hrubého (po DPH a provizi obchodu).

- Kupuje každý … návštěvník1 000. 5 000.200.
- Cena vstupu do města („oběd“)6,50 € 5 €8 €
- Zahrnout skupiny měst

### Čistý roční příjem podle města

Tmavá část pruhu = nízký odhad, světlá = vysoký odhad. Seřazeno podle vysokého odhadu. Graf se mění s posuvníky a přepínači.

|   |   |   |
|---|---|---|
| **Řím** antika, Vatikán, příběh na každém rohu |  | 30 tis. € – 50 tis. € |
| **Barcelona** Gaudí, Gotická čtvrť; město chce rozptýlit davy |  | 32 tis. € – 38 tis. € |
| **Krakov** Wawel, Kazimierz, výlety do Osvětimi a Věličky |  | 5 tis. € – 33 tis. € |
| **Praha** Hrad, Most, Josefov, pověsti; 77 % cizinců na Hradě |  | 18 tis. € – 23 tis. € |
| **Budapešť** dvě města, lázně, 1956; nejvíc Britů |  | 16 tis. € – 18 tis. € |
| **Vídeň** Habsburkové, hudba; 4 h z Prahy, němčina |  | 14 tis. € – 17 tis. € |
| **Florencie** renesance na 5 km², Medicejové |  | 12 tis. € – 16 tis. € |
| **Benátky** nejhustší příběhy, ale silná konkurence |  | 15 tis. € |
| **Český Krumlov** Rožmberkové; 25 % cizinců z Tchaj-wanu |  | 1 tis. € – 6 tis. € |
| **Kutná Hora** stříbro, kostnice, Kingdom Come |  | 1 tis. € – 4 tis. € |
| **Plzeň + Šumava** pivo, Patton 1945, Šumava |  | 2 tis. € – 3 tis. € |

- Pilot ČR
- Řím
- Další doporučená města

| Lokalita | Návštěvníci / rok | Jazykové pokrytí | Kupující | Hrubé tržby | Čistý příjem |
|---|---|---|---|---|---|
| **Praha** nízký: zahraniční hosté (≈ 4/5); vysoký: všichni ubytovaní 2025 [zdroj](https://www.praguedaily.news/2026/02/12/prague-welcomes-over-eight-million-tourists-in-2025-luxury-segment-records-significant-growth/) | 6,6 mil. – 8,3 mil. | 62 % | 4 066 – 5 094 | 26 tis. € – 33 tis. € | 18 tis. € – 23 tis. € |
| **Kutná Hora** nízký: chrám sv. Barbory 2025; vysoký: odhad města (≈ 1 mil./rok, starší údaj) [zdroj](https://tourdata.cz/wp-content/uploads/2026/06/Navstevnost_TC_2025_CZ.pdf) · [zdroj 2](https://magazin.aktualne.cz/cestovani/kutna-hora-overtourismem-zatim-netrpi-za-pet-let-ale-muze-by/r~a67d0ba0a26111e993a6ac1f6b220ee8/?lp=1) | 296 tis. – 1 mil. | 77 % | 229 – 772 | 1 tis. € – 5 tis. € | 1 tis. € – 4 tis. € |
| **Český Krumlov** nízký: ubytovaní hosté 2025 (ČSÚ); vysoký: všichni návštěvníci (≈ 2 mil., odhad) [zdroj](https://csu.gov.cz/jhc/navstevnost-hromadnych-ubytovacich-zarizeni-jihoceskeho-kraje-podle-obci-v-roce-2025) · [zdroj 2](https://travelbible.cz/cesky-krumlov-pruvodce/) | 232 tis. – 2 mil. | 63 % | 147 – 1 268 | 1 tis. € – 8 tis. € | 1 tis. € – 6 tis. € |
| **Plzeň + Šumava** nízký: okresy Plzeň-město + Klatovy 2025; vysoký: celý Plzeňský kraj [zdroj](https://csu.gov.cz/plk/kapacita-a-navstevnost-hromadnych-ubytovacich-zarizeni-cestovniho-ruchu-v-okresech-plzenskeho-kraje-v-roce-2025) · [zdroj 2](https://csu.gov.cz/plk/cestovni-ruch-v-plzenskem-kraji-v-roce-2025) | 605 tis. – 913 tis. | 81 % | 492 – 743 | 3 tis. € – 5 tis. € | 2 tis. € – 3 tis. € |
| **Řím** nízký: příjezdy dle ISTAT 2025; vysoký: EBTL 2025 (Svatý rok). Zdroje se liší v metodice [zdroj](https://www.cheaperthancars.com/data-hub/italy/statistics/cities/rome-tourism-statistics/) · [zdroj 2](https://www.turismoroma.it/en/news/record-tourism-rome-2025) | 13,5 mil. – 22,9 mil. | 48 % | 6 534 – 11 084 | 42 tis. € – 72 tis. € | 30 tis. € – 50 tis. € |
| **Vídeň** odvozeno: 20,1 mil. nocí 2025 ÷ ~2,4 noci (náš odhad); nízký = 83 % zahraničních [zdroj](https://b2b.wien.info/en/newsroom/pressservice/vienna-2025-performance-report-1095370) | 6,9 mil. – 8,4 mil. | 45 % | 3 133 – 3 814 | 20 tis. € – 25 tis. € | 14 tis. € – 17 tis. € |
| **Budapešť** nízký: zahraniční hosté 2025; vysoký: všichni hosté [zdroj](https://dailynewshungary.com/hungary-tourism-smashes-all-records-in-2025-latest/) · [zdroj 2](https://etias.com/articles/hungary-smashes-tourism-record-with-20m-visitors-in-2025) | 7 mil. – 8,1 mil. | 50 % | 3 472 – 4 018 | 23 tis. € – 26 tis. € | 16 tis. € – 18 tis. € |
| **Krakov** nízký: zahraniční (vč. jednodenních) 2025; vysoký: všichni vč. domácích jednodenních [zdroj](https://krakow.pl/aktualnosci/324027,30,komunikat,krakow_analizuje_ruch_turystyczny.html) | 2,5 mil. – 16,3 mil. | 44 % | 1 123 – 7 183 | 7 tis. € – 47 tis. € | 5 tis. € – 33 tis. € |
| **Barcelona** nízký: zahraniční návštěvníci města 2025; vysoký: všichni návštěvníci města [zdroj](https://ajuntament.barcelona.cat/turisme/en/latest-news/news/barcelona-recorded-261-million-visitors-and-14041-billion-in-2025-1611665) | 13,4 mil. – 16 mil. | 52 % | 6 968 – 8 320 | 45 tis. € – 54 tis. € | 32 tis. € – 38 tis. € |
| **Florencie** metropolitní oblast 2025 (ISTAT); nízký: zahraniční [zdroj](https://roadgenius.com/statistics/tourism/italy/florence/) | 4,7 mil. – 6,2 mil. | 58 % | 2 697 – 3 596 | 18 tis. € – 23 tis. € | 12 tis. € – 16 tis. € |
| **Benátky** jen ubytovaní (ISTAT 2025); jednodenní návštěvníci nejsou započteni [zdroj](https://www.cheaperthancars.com/data-hub/italy/statistics/cities/venice-tourism-statistics/) | 5,9 mil. | 56 % | 3 304 | 21 tis. € | 15 tis. € |
| Celkem | 61,6 mil. – 95,9 mil. | 51 % | 32 164 – 49 194 | 209 tis. € – 320 tis. € | 146 tis. € – 224 tis. € |

Hodnoty jsou uvedené jako „nízký – vysoký“. Výnos už zohledňuje jazykové pokrytí (viz níže). Čísla se počítají živě z posuvníků a přepínačů.

### Jazyky a jejich vliv na výnos

Koupí jen ten, kdo obsahu rozumí. Pro každé město odhadujeme jazykový mix návštěvníků podle původu hostů. Kdo nemá svůj jazyk, poslechne si s určitou pravděpodobností angličtinu. **Jazykové pokrytí** pak násobí výnos v tabulce i v grafu výše. Zvolte jazyky v nabídce:

Kdo nemá svůj jazyk, poslechne si angličtinu40 %

#### Kolik přinese každý jazyk

Roční čistý příjem navíc (vysoký odhad, aktivní skupiny měst). U jazyků v nabídce je to ztráta při jejich vypuštění. Seřazeno od nejcennějšího.

|   |   |   |
|---|---|---|
| **angličtina** v nabídce · ztráta při vypuštění |  | +206 tis. € |
| **italština** zatím ne · zisk po přidání |  | +44 tis. € |
| **polština** zatím ne · zisk po přidání |  | +39 tis. € |
| **němčina** zatím ne · zisk po přidání |  | +24 tis. € |
| **španělština** zatím ne · zisk po přidání |  | +15 tis. € |
| **francouzština** zatím ne · zisk po přidání |  | +11 tis. € |
| **čeština** v nabídce · ztráta při vypuštění |  | +11 tis. € |
| **čínština** zatím ne · zisk po přidání |  | +5 tis. € |
| **korejština** zatím ne · zisk po přidání |  | +2 tis. € |
| **japonština** zatím ne · zisk po přidání |  | +2 tis. € |

#### Doporučené pořadí jazyků

1. **Angličtina + čeština** (beta). Angličtina je univerzální záloha, čeština pokrývá domácí turisty v regionech: v Plzni a Kutné Hoře tvoří většinu.
2. **Němčina**. Největší zahraniční skupina v Praze (982 tis.) i v Plzni, k tomu silná ve Vídni a Krumlově.
3. **Italština a španělština**, až se otevře Řím a Barcelona. Domácí turisté tam tvoří velký podíl.
4. **Čínština** (tradiční znaky kvůli Tchaj-wanu) pro Krumlov. Tam je asijský host nejčastější.
5. **Korejština a japonština**: malé objemy, ale vysoký zájem o památky (podle CzechTourism vyhledávají památky v 88–94 % aktivit).

Každý jazyk stojí namluvení (lidský hlas), a proto se vyplatí jen tam, kde graf vlevo ukazuje víc, než stojí produkce. Jazykové mixy jsou **náš odhad** z dat o původu hostů (ČSÚ, Venezia, ISTAT, Wien Tourismus, MOT Kraków). Ochota poslouchat v angličtině je předpoklad.

### Součty podle skupin

Čistý roční příjem při zvoleném podílu a ceně, včetně vypnutých skupin.

|   |   |   |
|---|---|---|
|  | **Pilot ČR** Praha, Kutná Hora, Český Krumlov, Plzeň + Šumava | 22 tis. € – 36 tis. € |
|  | **Řím** Řím | 30 tis. € – 50 tis. € |
|  | **Další doporučená města** Vídeň, Budapešť, Krakov, Barcelona, Florencie, Benátky | 94 tis. € – 138 tis. € |

Výběr dalších měst je náš návrh. Kritéria: hustota příběhů na km², podíl zahraničních turistů, dostupnost z Prahy a jazyková blízkost.

### Jak číst „každý tisící“

- 1 ‰ návštěvníků je ambiciózní, ale realistický cíl. Odpovídá třeba tomu, že aplikaci si nainstaluje 2 % návštěvníků a z nich zaplatí 5 %. Oba poměry jsou **naše předpoklady**, ověří je beta v sezóně 2027.
- Zahrnuté jsou jen vstupy do měst. Kafe, rodinné balíčky a instituce jsou navíc. Kafe přidá spíš desítky procent, ne násobky.
- Rok 2025 byl v Římě jubilejní (Svatý rok), takže vysoký odhad je spíš strop.
- Při jen-českém scénáři jde o příjem, ze kterého lze financovat obsah a marketing, ne však plný tým. Proto je Řím (nebo jiné velké město) logický druhý krok.

---

*Kapitola 3 · pokračování*

## Kolik míst musí mít každé město

Placená sekce za cenu oběda dává smysl, jen když posluchač neprojde všechno za hodinu. Pravidla, ze kterých počítáme (náš návrh):

- ≥ 10 POI / km² Hustota v jádru Další příběh do 3 minut chůze (~150–250 m).
- 8–15 POI Jedna trasa 60–90 minut chůze s poslechem; 1–3 min na příběh.
- ≥ 2 trasy Minimum pro placenou sekci Posluchač za cenu oběda dostane aspoň půl dne obsahu.
- 1,5 příběhu Na jedno POI U ikon 2–4 pohledy (dětský, pověst, fakt), u menších bodů 1.

| Město | Jádro km² | Minimum POI | Cíl POI | Tras | Nahrávek | Hodin audia | Kotevní místa |
|---|---|---|---|---|---|---|---|
| **Praha** Hradčany, Malá Strana, Staré a Nové Město, Josefov, Vyšehrad | 6 | 60 | 150 | 6 | 450 | 15 | Hrad, Karlův most, orloj, Josefov, Vyšehrad |
| **Kutná Hora** historické centrum + Sedlec | 1,5 | 20 | 40 | 2 | 120 | 4 | sv. Barbora, kostnice, Vlašský dvůr, stříbrný důl |
| **Český Krumlov** centrum v meandru + zámek | 0,8 | 20 | 35 | 2 | 105 | 4 | zámek, Plášťový most, Latrán, Egon Schiele |
| **Plzeň + Šumava** centrum Plzně + 3 výletní body na Šumavě | 2 | 25 | 50 | 3 | 150 | 5 | Prazdroj, katedrála, Patton 1945, Šumava |
| **Řím** centro storico, Vatikán, Trastevere, Kolosseum | 15 | 120 | 300 | 10 | 900 | 30 | Kolosseum, Fórum, Pantheon, Vatikán, Trevi |
| **Vídeň** Innere Stadt, Ringstraße, Schönbrunn | 5 | 60 | 150 | 6 | 450 | 15 | Hofburg, štěpánský dóm, Schönbrunn, Ring |
| **Budapešť** Buda (hrad), Pešť (centrum), nábřeží | 6 | 60 | 140 | 6 | 420 | 14 | Hrad, parlament, Řetězový most, židovská čtvrť |
| **Krakov** Staré Město, Wawel, Kazimierz + 2 výlety | 3 | 50 | 120 | 5 | 360 | 12 | Wawel, Rynek, Kazimierz, Osvětim, Vělička |
| **Barcelona** Gotická čtvrť, Eixample, Montjuïc | 8 | 70 | 160 | 7 | 480 | 16 | Sagrada Família, Gotická čtvrť, Park Güell, Rambla |
| **Florencie** historické centrum (UNESCO), Oltrarno | 5 | 50 | 110 | 5 | 330 | 11 | Dóm, Ponte Vecchio, Uffizi, Medicejové |
| **Benátky** sestiere historického centra + ostrovy | 7 | 60 | 130 | 6 | 390 | 13 | San Marco, Rialto, Gheto, Murano |
| Celkem (aktivní skupiny) |  | 595 | 1 385 | 58 | 4 155 | 139 |  |

**Minimum** = spustit placenou sekci. **Cíl** = město plně pokryté na 2+ dny. Nahrávky = cíl POI × 1,5 příběhu na POI × 2 jazyky v nabídce (přepínač jazyků v kapitole 3). Plochy jader jsou přibližné a všechny hodnoty jsou náš odhad, ne měření.

### Pilot je zvládnutelný

Praha + Kutná Hora na minimum = 80 POI. To odpovídá cíli 100 nahrávek v harmonogramu, pokud se začne jednou trasou v každém městě a další se přidávají s komunitou.

### Jazyky násobí práci

Každý další jazyk znamená namluvit znovu všechny příběhy. Proto platí: v novém městě nejdřív minimum POI v angličtině a další jazyk až tam, kde graf jazyků ukazuje největší přínos.

### Hustota před počtem

Lepší je 20 POI na jedné souvislé trase než 60 roztroušených po celém městě. Posluchač musí mít další příběh do 3 minut chůze, jinak paywall ztrácí smysl („další příběh je 40 m odtud“).

---

*Kapitola 3 · pokračování*

## Náklady na vývoj a provoz

Počítáme jen to, co se skutečně musí zaplatit: backend, úložiště, poplatky obchodům a služby třetích stran. Naše práce v tom není. Revize 2 vychází ze skutečné architektury ze specifikace (Supabase, Firebase, Sentry, Resend, Netlify/Vercel). Zvolte fázi:

- 1 075 Kč — měsíčně
- 12 900 Kč — ročně (včetně ročních poplatků)
- ≈ 600 Kč — jednorázově na start
- 2 % — ročních nákladů z čistého příjmu pilotu ČR (nízký odhad). Jednorázově: Google Play $25.

| Položka | Na co a jak počítáno | Kč / měsíc | Kč / rok | Jistota |
|---|---|---|---|---|
| **Supabase Pro: produkce** Supabase | DB, Auth, Storage, Edge Functions. $25 měsíčně vč. 100 tis. MAU, 8 GB DB, 100 GB souborů, 250 GB přenosu. Při rozšíření odhad +$15 za překročení. [zdroj](https://www.stackrev.net/en/hosting-platforms/supabase-pricing) | 575 Kč | 6 900 Kč | ceník |
| **Supabase: staging projekt** Supabase | Druhý projekt ve stejné organizaci. Platí se jen compute Micro, cca $10. [zdroj](https://www.jetadmin.io/blog/supabase-pricing-2026-guide-to-plans-limits-and-real-world-costs/) | 230 Kč | 2 760 Kč | ceník |
| **Audio: doručení při růstu** Cloudflare R2 | Do 250 GB přenosu stačí Supabase Storage. Potom hotové audio na R2: $0,015/GB/měs., přenos dat zdarma. [zdroj](https://filebase.com/blog/cloudflare-r2-pricing-costs-savings-and-alternatives-in-2026/) | 0 Kč | 0 Kč | odhad |
| **Push + Crashlytics** Firebase | FCM a Crashlytics jsou zdarma bez limitu zpráv. | 0 Kč | 0 Kč | ceník |
| **Apple Developer Program** Apple | $99 ročně, rozpočítáno na měsíc. [zdroj](https://www.choicely.com/tutorials/how-much-does-it-cost-to-publish-an-app) | 190 Kč | 2 280 Kč | ceník |
| **Doména + DNS** registrátor, Cloudflare | Jedna doména (.app / .cz), DNS a certifikáty zdarma. | 30 Kč | 360 Kč | odhad |
| **Přepis nahrávek (AI v zákulisí)** Whisper na VPS nebo API | Přepis pro kontrolu kvality a vyhledávání. Na VPS zdarma (pomaleji), přes API řádově haléře za minutu. | 50 Kč | 600 Kč | odhad |
| **Strojový překlad textů** překladové API | Jen popisky a texty se štítkem „strojově přeloženo“, ne audio. Do limitu bezplatné úrovně zdarma. | 0 Kč | 0 Kč | odhad |
| **Transakční e-maily** Resend | Ověření účtu, doklady o platbě, pozvánky autorů. Bezplatný tarif do 3 000 e-mailů měsíčně, pak cca $20. | 0 Kč | 0 Kč | odhad |
| **Monitoring chyb webu** Sentry | Bezplatný tarif Developer pro 1 uživatele. Při více lidech v týmu placený Team. | 0 Kč | 0 Kč | odhad |
| **Hosting webu** Netlify / Vercel | Statický build. Netlify free stačí. Vercel Hobby nepovoluje komerční provoz, Pro stojí $20. | 0 Kč | 0 Kč | odhad |
| **Licence geofencingu** Transistorsoft | flutter_background_geolocation vyžaduje pro Android release placenou licenci (GAP E). Cenu ověřit; alternativou je nativní geofencing. | 0 Kč | 0 Kč | ověřit |
| **Mapové podklady** PMTiles (OpenMapTiles / Protomaps) | Vlastní vektorové dlaždice v úložišti místo tile.openstreetmap.org, jehož zásady offline stahování nepovolují. [zdroj](https://operations.osmfoundation.org/policies/tiles/) | 0 Kč | 0 Kč | odhad |

Kurz orientačně 25 Kč/€ a 23 Kč/USD. **Ceník** = převzato z ceníku poskytovatele. **Odhad** = náš výpočet objemu (počet nahrávek, poslechů, uživatelů). Provize obchodů (15 %) a DPH už jsou odečtené v příjmech, sem je nepočítáme.

### Architektura

- **Supabase**: databáze, přihlášení, úložiště a 15 Edge Functions. Na Pro tarifu je v ceně 100 000 aktivních uživatelů, 100 GB souborů a 250 GB přenosu dat.
- **Firebase**: push notifikace a Crashlytics, zdarma.
- **Web** (admin, autoři, účet): statický build na Netlify nebo Vercel. Pozor: Vercel Hobby nepovoluje komerční provoz.

### vpsFree a R2 až při růstu

Původní návrh s vpsFree odpadá, protože backend je postavený na Supabase. Úzké hrdlo je jediné: přenos audia, až budou tisíce lidí stahovat celá města offline. Jakmile se blíží limitu 250 GB měsíčně, přesunout hotové audio na Cloudflare R2, kde je přenos dat zdarma.

### Co v tabulce není

Honoráře mluvčím, kurátor, testovací kampaně (desítky USD), účetní a daňový poradce, testovací telefony. Nejde o infrastrukturu, ale v rozpočtu je potřeba s nimi počítat. Pravděpodobně budou řádově vyšší než servery.

---

*Kapitola 4*

## Review rozhodnutí ze schůzky

- Souhlas · 5
- Doladit · 7
- Pozor · 3

- Souhlas Nativní aplikace Zápis: „Aplikace/web“ spustí audio v perimetru.
- Flutter aplikace s geofencingem na pozadí, registruje vždy nejbližších 100 bodů. Web slouží pro admin, autory a účet.
- **Návrh:** Ponechat. Zbývá ověření na zařízení (geofence, push, deep linky). Viz PS-P3.3.

- Pozor Platby v aplikaci Zápis: Revolut, Stripe / Google Pay / Apple Pay, Comgate.
- Digitální obsah odemčený v aplikaci musí jít přes nákup v aplikaci. Revolut se navíc potvrzuje tlačítkem „zaplatil jsem“ bez ověření. [App Review 3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- **Návrh:** IAP (StoreKit / Play Billing) v aplikaci, Comgate a Stripe jen na webu, Revolut jen s ručním schválením dokladu. Viz kap. 0.3.

- Pozor TTS fallback Zápis: Bez nahrávky čte systémový hlas.
- Odporuje hlavnímu rozdílu „lidský hlas“. Kvalita se liší podle telefonu a jazykového balíčku.
- **Návrh:** TTS jen pro bezplatné texty se štítkem „strojový hlas“. Placená sekce jen s nahrávkami. Viz kap. 0.4.

- Doladit Bezplatný limit Zápis: 1 audio denně.
- Denní limit dá turistovi na 2–3denním výletu víc ochutnávek než měsíční.
- **Návrh:** free_visit_log přepnout z měsíce na den. Limit číst z payment_config, aby šel měnit bez vydání nové verze.

- Doladit Perimetr 100 m Zápis: Spouštění ~100 m od POI.
- V centru Prahy bude v okruhu 100 m víc bodů najednou.
- **Návrh:** Výchozí hodnotu snížit na 40 m pro centra měst a přidat frontu přehrávání (spec. ji nemá).

- Souhlas Lidský hlas Zápis: Reální mluvčí, ne AI ani celebrity.
- Konkurence nabízí AI TTS jako levnou variantu, lidský hlas nás tedy odliší. [SmartGuide](https://blog.smart-guide.org/en/how-to-provide-self-guided-tours-for-visitors-easily)
- **Návrh:** Ponechat. Připravit standard nahrávání a vzorovou nahrávku.

- Pozor Obsah z Wikipedie Zápis: Začít s volnými zdroji.
- Licence CC BY-SA vyžaduje uvést autory a šířit odvozené dílo pod stejnou licencí. [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.cs)
- **Návrh:** Wikipedie jen jako podklad, skripty vlastní. Jinak viditelně uvést licenci.

- Doladit Kafe za ~1 USD Zápis: Mikroplatba „kup mi kafe“.
- Platba kartou 3,4 % + 0,35 vezme z 1 USD ~38 %. [VoiceMap docs](https://docs.voicemap.me/tour-publishers/tour-payment-calculations/)
- **Návrh:** Kafe za 1,99 € = 3 audia, pivo za 2,99 € = celé místo.

- Souhlas Město za cenu oběda Zápis: Celé město za 5–8 USD/EUR.
- Odpovídá trhu: komunitní trasa po Vatikánu stojí 8–12 €. [Musa](https://www.musa.guide/en/resources/best-audio-guide-vatican-museums)
- **Návrh:** Ponechat. Praha a Řím za 7,99 €, menší města za 4,99–5,99 €.

- Doladit Kredity za kvalitní obsah Zápis: Odměny podmíněné vysokým hodnocením.
- Prostý průměr 5★ se dá zmanipulovat několika účty.
- **Návrh:** Vážené skóre + jen ověřená hodnocení (GPS + ≥ 60 % poslechu) + měsíční strop (kap. 2.2).

- Doladit Výplaty přes Revolut Zápis: Fáze 2: výplaty autorům.
- Výplaty znamenají KYC, poplatky a daňovou agendu. U Stripe Connect stojí aktivní účet 2 € měsíčně. [Stripe](https://stripe.com/connect/pricing)
- **Návrh:** Nahradit kredity. Spropitné napřímo mimo nás. Hotovost až pro top autory, pokud ji tržby unesou.

- Souhlas Jeden profil Zápis: Posluchač a autor pod jedním loginem.
- Zjednoduší cestu od posluchače k autorovi.
- **Návrh:** Ponechat. Edge-case: autor nesmí hodnotit ani odemykat vlastní obsah kredity.

- Doladit Pět pilotních lokalit Zápis: Praha, Kutná Hora, Plzeň, Most, Brdy.
- Pět lokalit rozmělní obsah. Praha přinese většinu tržeb, Kutná Hora je nejsilnější výlet.
- **Návrh:** Beta: Praha + Kutná Hora. Český Krumlov a Plzeň v roce 2028, Most a Brdy jako komunitní obsah bez placené sekce.

- Souhlas Instituce později Zápis: Státní instituce, zoo, muzea odloženy.
- Instituce budou chtít vidět čísla poslechů a referenční lokalitu.
- **Návrh:** Ponechat. Data z bety připravit jako podklad pro Zoo Praha a další.

- Doladit Jazyky CZ/EN Zápis: Primárně angličtina a čeština.
- Němci jsou v Praze největší zahraniční skupinou (982 tis. v roce 2025). [Prague Daily](https://www.praguedaily.news/2026/02/12/prague-welcomes-over-eight-million-tourists-in-2025-luxury-segment-records-significant-growth/)
- **Návrh:** Němčinu jako třetí jazyk podpořit bonusem za nedostatkový obsah. Pro Krumlov zvážit čínštinu (Tchaj-wan tvoří 25 % cizinců).

---

*Kapitola 5*

## Hrozby a rizika

Hodnocení vychází z našeho úsudku nad zdroji v tomto dokumentu, nejde o měření. Největší hrozby nejsou technické. Jsou to **prázdná mapa** (málo kvalitního obsahu), **nikdo o nás neví** (distribuce) a **ztráta důvěry** (špatný příběh, únik polohy, podvod s kredity).

### 5.1 Co musíme zvládnout bez problémů

Nevyjednatelné minimum. Pokud cokoliv z toho selže, posluchač aplikaci smaže a už se nevrátí. Každá položka má měřitelné kritérium, bez jehož splnění nejde placená sekce ven.

- 01 Spuštění na správném místě Audio, které začne o ulici vedle nebo vůbec, zničí hlavní slib produktu. **Kritérium:** ≥ 95 % spuštění do 30 m od bodu v pilotních trasách; žádné dvojité přehrání.
- 02 Přehrávání bez výpadku V Kutné Hoře i v Krumlově je slabý signál. Rodina s dětmi nebude čekat na načítání. **Kritérium:** offline režim pro koupené město; start audia < 1 s.
- 03 Baterie a data Turista potřebuje telefon na fotky a mapy celý den. **Kritérium:** < 8 % baterie za hodinu aktivní procházky.
- 04 Platba na 1 tap Kafe a oběd jsou impulzivní nákupy. Každý krok navíc snižuje konverzi. **Kritérium:** nákup v aplikaci (StoreKit / Play Billing), Apple/Google Pay, odemčení do 3 s, obnovení nákupu na novém telefonu.
- 05 Kvalita a pravdivost obsahu Jeden nepravdivý nebo urážlivý příběh na Pražském hradě je titulek v médiích. **Kritérium:** každá nahrávka nad branou zkontrolovaná kurátorem; nahlášení vyřízeno do 24 h.
- 06 Integrita kreditů Kredity jsou měna. Chyba nebo podvod znehodnotí odměny pro poctivé autory. **Kritérium:** neměnná účetní kniha kreditů, audit log, strop a detekce farem.
- 07 Ochrana polohy (GDPR) Poloha je osobní údaj, u rodin s dětmi obzvlášť citlivý. **Kritérium:** poloha se zpracovává v zařízení, na server jde jen „byl u bodu X“; souhlas, výmaz účtu.
- 08 Práva k nahrávkám Bez licence od autora nesmíme obsah prodávat, a už vůbec ne institucím. **Kritérium:** licenční souhlas při nahrání (nevýhradní, celosvětová, pro komerční užití); souhlas mluvčího.

### 5.2 Mapa rizik

Čísla odkazují do registru níže. Čím tmavší pole, tím dřív řešit. Přepněte, kam se rizika posunou po eliminačních krocích.

| vysoký | R10 |
|---|---|
| R3 R4 R6 R9 | R1 R2 R12 |
| střední | R8 R11 |
| R5 R7 R13 R18 R19 R20 | R15 R17 |
| nízký |  |
| R14 | R16 |
|  | nízká |
| střední | vysoká |

pravděpodobnost → · dopad ↑

### 5.3 Pět největších hrozeb a jak je eliminovat

|   |   |
|---|---|
| R1 | **Prázdná mapa** 9 → 3 Před betou natočit 50 vlastních „startovních“ nahrávek na 2 trasách · Spustit trasu, až když má ≥ 15 nahrávek nad branou · Bonus +30 kr. za první obsah u místa · Smlouva se 3 spolky/školami o měsíčním přísunu obsahu |
| R2 | **Nikdo o nás neví** 9 → 4 QR stojánky na recepcích 20 hotelů a hostelů a v infocentrech · ASO: název a popis v 5 jazycích, screenshoty konkrétních míst · Sdílitelná kartička výletu jako virální smyčka · Placené kampaně až při ceně za instalaci < 1 € |
| R12 | **Únik celé databáze z webu** 9 → 1 Odstranit VITE_SUPABASE_SERVICE_ROLE_KEY z webu i z .env · Admin čte přes anon klíč + RLS politiku „je v admin_users“, zápisy přes Edge Functions · Rotovat service_role klíč, stripe_secret_key přesunout z payment_config do Secrets · CI kontrola: build selže, pokud obsahuje service_role |
| R3 | **Konverze pod 1 ‰** 6 → 4 A/B test 1 vs. 2 bezplatných audií denně · Paywall ve chvíli, kdy stojí u dalšího bodu („další příběh je 40 m odtud“) · Rodinný balíček, platnost 30 dní · Při < 0,5 ‰ po 6 týdnech přidat B2B: hotely platí za přístup pro hosty |
| R4 | **Zamítnutí v obchodech kvůli platbám** 6 → 2 StoreKit / Play Billing produkty: Kafe, Pivo, Město, Rodina, Celé Česko · Ověření účtenky serverem (Edge Function) → user_access · V aplikaci žádný odkaz na Revolut ani Comgate · Obnovení nákupů na novém telefonu |

### 5.4 Registr rizik a plán eliminace

Varovný signál = co sledovat, abychom riziko zachytili dřív, než se projeví naplno. Eliminace = konkrétní kroky s termínem. Zbytkové riziko = hodnocení po jejich provedení (náš odhad).

| # | Oblast | Riziko | P × D | Varovný signál | Eliminace: kroky | Zbytkové | Kdo |
|---|---|---|---|---|---|---|---|
| R1 | Obsah | **Prázdná mapa** Málo kvalitních nahrávek, uživatel nenajde nic poblíž. | 3 × 3 = 9 | < 3 nahrávky nad branou na km² centra v dubnu 2027 | Před betou natočit 50 vlastních „startovních“ nahrávek na 2 trasách · Spustit trasu, až když má ≥ 15 nahrávek nad branou · Bonus +30 kr. za první obsah u místa · Smlouva se 3 spolky/školami o měsíčním přísunu obsahu | 1 × 3 = 3do III/2027 | LSR |
| R2 | Distribuce | **Nikdo o nás neví** Turista hledá v App Store „Prague audio guide“ a najde konkurenci. | 3 × 3 = 9 | cena za instalaci > 1 € v testovacích kampaních | QR stojánky na recepcích 20 hotelů a hostelů a v infocentrech · ASO: název a popis v 5 jazycích, screenshoty konkrétních míst · Sdílitelná kartička výletu jako virální smyčka · Placené kampaně až při ceně za instalaci < 1 € | 2 × 2 = 4do VI/2027 | LSR |
| R3 | Trh | **Konverze pod 1 ‰** Lidé poslouchají jen bezplatné denní audio. | 2 × 3 = 6 | po 6 týdnech sezóny < 0,5 ‰ kupujících | A/B test 1 vs. 2 bezplatných audií denně · Paywall ve chvíli, kdy stojí u dalšího bodu („další příběh je 40 m odtud“) · Rodinný balíček, platnost 30 dní · Při < 0,5 ‰ po 6 týdnech přidat B2B: hotely platí za přístup pro hosty | 2 × 2 = 4do VIII/2027 | LSR |
| R4 | Platformy | **Zamítnutí v obchodech kvůli platbám** Aplikace prodává digitální obsah přes Revolut, Stripe a Comgate místo nákupu v aplikaci. | 2 × 3 = 6 | zamítnutí v review s odkazem na pravidlo 3.1.1 | StoreKit / Play Billing produkty: Kafe, Pivo, Město, Rodina, Celé Česko · Ověření účtenky serverem (Edge Function) → user_access · V aplikaci žádný odkaz na Revolut ani Comgate · Obnovení nákupů na novém telefonu | 1 × 2 = 2do XI/2026 | VTM |
| R5 | Produkt | **Nepřesné GPS v uličkách** Úzké ulice a mosty dávají chybu 20–50 m. | 2 × 2 = 4 | stížnosti „hraje špatný příběh“ | Poloměr jako atribut POI, kalibrace v terénu · Tlačítko „jsem tady“ a seznam bodů v okolí jako záloha · Testovací průchod každé trasy před zveřejněním | 1 × 1 = 1do IV/2027 | VTM |
| R6 | Obsah | **Nepravdivý nebo urážlivý obsah** Fámy, politika, nevhodné historky na pietních místech (kostnice, Osvětim). | 2 × 3 = 6 | nahlášení > 1 % poslechů | Kurátor schvaluje každou nahrávku před branou · Kodex pro pietní místa (kostnice, hřbitovy, místa obětí) · Tlačítko „nahlásit“ a stažení do 24 h · AI předkontrola přepisu na rizikové výrazy | 1 × 2 = 2do III/2027 | LSR |
| R7 | Finance | **Farmení kreditů** Falešné účty si navzájem hodnotí a poslouchají. | 2 × 2 = 4 | shluky hodnocení ze stejného zařízení / IP | Hodnotí jen ověřený posluchač (GPS + 60 % poslechu) · Vážené skóre s m = 20 · Strop 300 kr./měsíc, 1 účet = 1 zařízení · Měsíční audit anomálií a zmrazení podezřelých účtů | 1 × 1 = 1do II/2027 | VTM |
| R8 | Finance | **Kredity kanibalizují tržby** Aktivní autoři si nikdy nic nekoupí. | 1 × 2 = 2 | odemčení kredity > 10 % všech | Kurz 30 kr. = 1 audio, 200 kr. = město · Platnost 12 měsíců · Při > 10 % odemčení kredity zdražit kurz | 1 × 1 = 1do VII/2027 | LSR |
| R9 | Právo | **Autorská práva a licence** Nahrávka s cizím textem (Wikipedie, průvodce) nebo hudbou v pozadí. | 2 × 3 = 6 | nahrávky bez vyplněného zdroje | Licenční souhlas při nahrání (nevýhradní, celosvětová, komerční) · Povinné pole „zdroj textu“, zákaz hudby v pozadí · Kontrola shody textu s Wikipedií · Postup pro stížnost držitele práv: stažení do 48 h | 1 × 2 = 2do II/2027 | LSR |
| R10 | Právo | **GDPR a data dětí** Sběr polohy, účty dětí, mluvčí-nezletilí. | 1 × 3 = 3 | žádost dozorového úřadu, stížnost | Poloha zpracovaná v zařízení, server ukládá jen „návštěvu bodu“ · Účty 16+, souhlas rodiče u nezletilých mluvčích · Zásady ochrany údajů + výmaz účtu v aplikaci · Posouzení vlivu (DPIA) před spuštěním | 1 × 1 = 1do III/2027 | VTM |
| R11 | Právo | **Kredity jako zdanitelný příjem** Úřad posoudí kredity jako nepeněžní plnění autorovi. | 1 × 2 = 2 | dotazy autorů / poradce | Písemné stanovisko daňového poradce · Kredity bez hotovostní hodnoty, nepřevoditelné · Text v obchodních podmínkách | 1 × 1 = 1do I/2027 | LSR |
| R12 | Bezpečnost | **Únik celé databáze z webu** service_role klíč v proměnné VITE_ se dostane do JavaScriptu v prohlížeči a obchází všechna RLS pravidla. | 3 × 3 = 9 | klíč nalezený v buildu webu (hledat „eyJ“ v dist/) | Odstranit VITE_SUPABASE_SERVICE_ROLE_KEY z webu i z .env · Admin čte přes anon klíč + RLS politiku „je v admin_users“, zápisy přes Edge Functions · Rotovat service_role klíč, stripe_secret_key přesunout z payment_config do Secrets · CI kontrola: build selže, pokud obsahuje service_role | 1 × 1 = 1do X/2026 | VTM |
| R13 | Konkurence | **Velký hráč přidá komunitní audio** SmartGuide, VoiceMap nebo Google přidají podobnou funkci. | 2 × 2 = 4 | oznámení konkurence | Exkluzivní spolupráce s lokálními spolky a školami · Vlastní katalog hlasů a příběhů (licence u nás) · Být první v Kutné Hoře a Krumlově | 2 × 1 = 2do průběžně | LSR |
| R14 | Trh | **Regulace overtourismu** Města omezují skupiny a průvodce (Benátky, Barcelona, kostnice s časovými sloty). | 2 × 1 = 2 | nová místní pravidla | Režim „jen se sluchátky“ · Trasy mimo hlavní body (rozptýlení davů) · Nabídnout městům data o pohybu návštěvníků jako protislužbu | 1 × 1 = 1do 2028 | LSR |
| R15 | Provoz | **Kapacita dvou lidí** Vývoj, obsah, marketing a podpora současně. | 3 × 2 = 6 | skluz > 4 týdny v harmonogramu | Brány mezi fázemi, nic se nespouští paralelně · Kurátor na DPP ze studentů · Gamifikaci a instituce odložit do 2028 | 2 × 1 = 2do XII/2026 | VTM |
| R16 | Trh | **Sezónnost** Tržby soustředěné do VII–X, v zimě skoro nic. | 3 × 1 = 3 | propad příjmů XI–III | Řím a jižní města jako protisezóna · Adventní a vánoční trasy (Praha, Vídeň) · Roční balíček pro všechna města | 2 × 1 = 2do 2028 | LSR |
| R17 | Platby | **Odemčení bez zaplacení** Revolut se potvrzuje tlačítkem „Ano, zaplatil jsem“. Edge Function pro udělení přístupu bere user_id a částku z požadavku. | 3 × 2 = 6 | user_access s metodou revolut bez transaction_id | Odstranit dialog „Ano, zaplatil jsem“ a grantAccess z klienta · Přístup uděluje jen webhook (Comgate/Stripe) nebo ověření účtenky IAP · Revolut jen na webu: status pending → ruční schválení dokladu v adminu · Edge Function bere user_id z JWT, ne z těla požadavku | 1 × 1 = 1do XI/2026 | VTM |
| R18 | Licence | **Porušení zásad OSM dlaždic** Aplikace stahuje dlaždice z tile.openstreetmap.org a ukládá je offline. | 2 × 2 = 4 | blokace User-Agentu, výzva od OSMF | Dlaždice z OpenMapTiles / Protomaps jako PMTiles v úložišti · Nebo MapTiler či Stadia s licencí pro offline · Atribuce © OpenStreetMap ponechat | 1 × 1 = 1do XII/2026 | VTM |
| R19 | Produkt | **TTS oslabí slib lidského hlasu** Body bez nahrávky přečte systémový hlas. | 2 × 2 = 4 | recenze „robotický hlas“ | audio_urls povinné pro POI v placené sekci · TTS jen u bezplatných textů se štítkem · Admin: přehled POI bez nahrávky jako úkol pro autory | 1 × 1 = 1do XII/2026 | LSR |
| R20 | Release | **Nejednotná identita aplikace** HeroDots / PlaceSecrets, cz.tuma.herodots, placesecrets://. | 2 × 2 = 4 | nesoulad deep linků a domény | Jeden název, bundle ID, doména a schéma deep linku · Prefix dokladů sjednotit (PS-) · Ověřit dostupnost názvu v obou obchodech a ochranné známky | 1 × 1 = 1do XI/2026 | LSR |

P × D = pravděpodobnost × dopad, každé na škále 1–3. Skóre 6–9 = řešit hned, 3–4 = sledovat, 1–2 = akceptovat. Po eliminaci nemá žádné riziko skóre vyšší než 4. Nejtvrdší zůstávají distribuce a konverze, ty se vyřeší jen daty z bety.

---

*Kapitola 6*

## Harmonogram podle sezóny

Na Pražském hradě byly v roce 2025 nejsilnějšími měsíci srpen, říjen a červenec ([iROZHLAS](https://www.irozhlas.cz/zpravy-domov/na-prohlidky-prazskeho-hradu-prislo-v-roce-2025-rekordnich-27-milionu-lidi_2601072231_cen)). V sedlecké kostnici přišlo jen za červenec a srpen 2025 přes 91 tisíc lidí ([Kutnohorský deník](https://kutnohorsky.denik.cz/zpravy-region/kostnice-zvladla-letni-napor-i-pres-time-sloty-se-navstevnost-temer-nezmenila/)). Placená sekce proto musí být spuštěná do července 2027.

- X–XII 2026 Sjednocení Bezpečnost a platby (PS-P0), jednotný název, free model a ceny podle plánu, hodnocení s ověřením, kredity do schématu. Staging, Firebase, právní texty. **Brána:** Žádný kritický nález; smoke test 6 kroků na zařízení projde.
- I–III 2027 Obsah + uzavřený test TestFlight a interní test Google Play. Najít 30 autorů v Praze a Kutné Hoře, natočit 100 nahrávek. **Brána:** 100 nahrávek ve 2 jazycích; ≥ 99 % relací bez pádu.
- IV–VI 2027 Beta zdarma Vše zdarma, hodnocení s GPS ověřením, kredity se připisují. Testovací kampaně za desítky USD. **Brána:** ≥ 60 nahrávek nad branou kvality.
- VII–X 2027 Placená sekce 1 audio denně zdarma, kafe / pivo / oběd. Kredity jdou utratit. **Brána:** ≥ 1 ‰ kupujících v Praze za sezónu.
- 2028 Rozšíření Český Krumlov, Plzeň. Test Říma s místními autory. První jednání s institucemi. **Brána:** Kladná marže na kampaních.

---

*Kapitola 7*

## Další kroky

Úkoly ze zápisu, doplněné o vlastníka, termín a měřitelný výstup. Vlastníky a termíny prosím potvrďte, jsou to jen návrhy.

| # | Úkol | Kdo | Do | Hotovo, když… |
|---|---|---|---|---|
| 1 | Odstranit service_role z webu: admin přes RLS + Edge Functions, rotovat klíč (PS-P0.1) | VTM | 31. 10. | v dist/ webu není service_role; starý klíč neplatí |
| 2 | Platby: IAP v aplikaci, Comgate/Stripe jen web, zrušit Revolut (PS-P0.2, P0.3) | VTM | 30. 11. | přístup vzniká jen z ověřené platby; testovací nákup v sandboxu |
| 3 | Rozhodnout finální název a identifikátory (PS-P0.4) | LSR | 15. 11. | jeden název v aplikaci, webu, doméně a bundle ID |
| 4 | Free model a ceny podle plánu: 1 audio/den, Kafe / Pivo / Město, platnost 30 dní (PS-P1.1, P1.2) | VTM | 30. 11. | hodnoty v payment_config, ne v kódu |
| 5 | Hodnocení jen s ověřenou návštěvou, vážené skóre (PS-P1.4) | VTM | 15. 12. | anonymní insert zrušen; skóre počítá server |
| 6 | Kredity: ledger, kurz, strop, platnost (PS-P1.3) | VTM | 31. 1. | migrace + RPC; pravidla z kap. 2 v obchodních podmínkách |
| 7 | Staging Supabase, Firebase projekt, Sentry DSN, zálohy (PS-P3.1) | VTM | 15. 11. | release jde nejdřív na staging |
| 8 | Mapové dlaždice mimo tile.openstreetmap.org (PS-P2.3) | VTM | 15. 12. | offline mapa z vlastních PMTiles |
| 9 | Právní texty, údaje provozovatele, revize právníkem | LSR | 30. 11. | Terms a Privacy bez placeholderů; URL v obchodech |
| 10 | Účty v obchodech, upload keystore se zálohou, finální ikona | LSR | 30. 11. | obě konzole aktivní; keystore uložený na 2 místech |
| 11 | Konzultace s daňovým poradcem ke kreditům | LSR | 31. 1. | písemné stanovisko |
| 12 | Smoke test na zařízení: registrace → nákup → offline → geofence → push → hodnocení → kredity | VTM | 31. 1. | všech 7 kroků projde na iOS i Androidu |
| 13 | Oslovit školy, spolky a DAMU v Praze a Kutné Hoře | LSR | 31. 1. | 30 potvrzených autorů |
| 14 | Standard nahrávání + vzorová nahrávka | LSR | 15. 1. | jednostránkový návod, 1 vzor CZ/EN |
| 15 | Prvních 100 nahrávek (Praha + Kutná Hora) | LSR | 31. 3. | 100 nahrávek ve 2 jazycích |
| 16 | Spustit betu zdarma | VTM | 15. 4. | veřejná beta, měření metrik |
| 17 | Testovací kampaně Meta / TikTok (desítky USD) | LSR | V–VI | známe cenu za instalaci a za kupujícího |
| 18 | Spustit placenou sekci | VTM | 1. 7. | kafe / pivo / oběd fungují, kredity jdou utratit |

Tučné červené číslo = blokuje další práci, začít s ním.

---

*Kapitola 8*

## Metriky bety

|   |   |
|---|---|
| Nahrávek nad branou kvality | ≥ 60 |
| Aktivních autorů (≥ 1 nahrávka / měsíc) | ≥ 30 |
| Instalace / návštěvníci Prahy | ≥ 1 % |
| Poslechnuto ≥ 60 % nahrávky | ≥ 70 % |
| Kupující / návštěvníci | ≥ 1 ‰ |
| Odemčení kredity / všechna odemčení | ≤ 10 % |

Cíle jsou výchozí odhad týmu, ne oborový benchmark.

*Kapitola 9*

## Otázky na příští schůzku

1. Finální název a identifikátor: PlaceSecrets, nebo HeroDots? Po prvním nahrání do obchodů už bundle ID nejde změnit.
2. Souhlasíte s nákupem v aplikaci (IAP) a s tím, že Revolut, Stripe a Comgate zůstanou jen na webu?
3. TTS: vypnout úplně, nebo nechat jen pro bezplatné texty se štítkem?
4. Kafe = 1 audio, nebo 3 audia? Doporučujeme 3 audia za 1,99 €.
5. Kurz kreditů: odpovídá 30 kreditů = 1 audio, 200 = město?
6. Má vstup do města platit 30 dní, nebo navždy?
7. Řím jako první zahraniční město, nebo nejdřív Vídeň/Budapešť (blíž, menší)?
8. Kdo je právní subjekt a kdo zodpovídá za podmínky kreditů?

---

*Zdroje*

## Seznam zdrojů

Ověřeno 15. 10. 2026. Údaje o konkurenci pocházejí z jejich vlastních materiálů. Daňové body jsou orientační, nejde o právní radu.

1. [Prague Daily: Praha 2025](https://www.praguedaily.news/2026/02/12/prague-welcomes-over-eight-million-tourists-in-2025-luxury-segment-records-significant-growth/) ČSÚ, 8,27 mil. návštěvníků, trhy
2. [CzechTourism: Návštěvnost turistických cílů 2025](https://tourdata.cz/wp-content/uploads/2026/06/Navstevnost_TC_2025_CZ.pdf) chrám sv. Barbory 296 tis.
3. [Aktuálně.cz: Kutná Hora](https://magazin.aktualne.cz/cestovani/kutna-hora-overtourismem-zatim-netrpi-za-pet-let-ale-muze-by/r~a67d0ba0a26111e993a6ac1f6b220ee8/?lp=1) odhad ≈ 1 mil./rok (starší článek)
4. [Kutnohorský deník: kostnice v létě](https://kutnohorsky.denik.cz/zpravy-region/kostnice-zvladla-letni-napor-i-pres-time-sloty-se-navstevnost-temer-nezmenila/) VII–VIII 2025: 91 599 lidí
5. [ČSÚ: Jihočeský kraj podle obcí 2025](https://csu.gov.cz/jhc/navstevnost-hromadnych-ubytovacich-zarizeni-jihoceskeho-kraje-podle-obci-v-roce-2025) Český Krumlov 232 tis. hostů
6. [Travel Bible: Český Krumlov](https://travelbible.cz/cesky-krumlov-pruvodce/) ≈ 2 mil. návštěvníků (odhad)
7. [ČSÚ: Plzeňský kraj, okresy 2025](https://csu.gov.cz/plk/kapacita-a-navstevnost-hromadnych-ubytovacich-zarizeni-cestovniho-ruchu-v-okresech-plzenskeho-kraje-v-roce-2025) Plzeň-město + Klatovy 605 tis.
8. [ČSÚ: Plzeňský kraj 2025](https://csu.gov.cz/plk/cestovni-ruch-v-plzenskem-kraji-v-roce-2025) 912 595 hostů
9. [Turismo Roma: rekord 2025](https://www.turismoroma.it/en/news/record-tourism-rome-2025) 22,9 mil. příjezdů, 12 mil. ze zahraničí
10. [Cheaper Than Cars: ISTAT Řím 2025](https://www.cheaperthancars.com/data-hub/italy/statistics/cities/rome-tourism-statistics/) 13,5 mil. příjezdů
11. [iROZHLAS: Pražský hrad 2025](https://www.irozhlas.cz/zpravy-domov/na-prohlidky-prazskeho-hradu-prislo-v-roce-2025-rekordnich-27-milionu-lidi_2601072231_cen) sezónnost
12. [Musa: audioprůvodci Vatikán](https://www.musa.guide/en/resources/best-audio-guide-vatican-museums) ceny konkurence
13. [VoiceMap: výpočet plateb](https://docs.voicemap.me/tour-publishers/tour-payment-calculations/) poplatky karty, podíl autorů
14. [VoiceMap fórum: 80 % royalties](https://forum.voicemap.me/t/publish-in-key-destinations-or-attractions-and-earn-80-royalties/3661) motivace v nedostatkových destinacích
15. [SmartGuide blog](https://blog.smart-guide.org/en/smartguide-allows-guiding-tourists-better-with-ai-and-ar-enhancements-supported-by-1-million-grant) AI TTS, grant EK
16. [Foliokit: Small Business Program](https://foliokit.io/blog/app-store-small-business-program) 15% provize
17. [Stripe Connect pricing](https://stripe.com/connect/pricing) poplatky za výplaty
18. [MobiLoud: PWA na iOS](https://www.mobiloud.com/blog/progressive-web-apps-ios/) omezení polohy na pozadí
19. [Creative Commons BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.cs) licence Wikipedie
20. [Apple App Review Guidelines 3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase) nákup v aplikaci pro digitální obsah
21. [OSMF Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/) zákaz hromadného a offline stahování
22. [Supabase: API keys](https://supabase.com/docs/guides/api/api-keys) service_role nikdy v prohlížeči
23. [StackRev: Supabase pricing (ověřeno 12. 10. 2026)](https://www.stackrev.net/en/hosting-platforms/supabase-pricing) Pro $25/měsíc
24. Interní podklady specification-prompts.md, spec-placesecrets-web.md, spec-prompts-admin.md, RELEASE-CHECKLIST.md
