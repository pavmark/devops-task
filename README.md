# Devops task
## About
Je zde několik playbooku které importuje hlavní playbook ve složce playbooks.


## Stage 1 - Základní setup VPS, Install dockeru

### Thought Process
- Nejdříve jsem se rozhodl podívat na ansible jelikož je to takový backbone tohoto projektu. S ansiblem mám malinko zkušenosti, napsal jsem si pár jednoduchých playbooku. Potřeboval jsem se o tom ale více naučit. Kouknul jsem tedy na pár videí, guidu a dokumentaci. Mám v plánu se ještě víde podívat na loopy a proměnné protože ty jsou hodně potřeba a často se u toho zaseknu a bere to čas.

- Pro začátek jsem kouknul jak to nějak organizovat a udělal podle toho pár složek i když některé jsou zatím nevyužité.

- Jako první jsem udělal playbook na install potřebných packagů a dockeru. To bylo celkem jednoduché jen jsem se na chvilku zasekl na přidávání repa. U přidáni je potřeba specifikovat architekturu, u jednoho guidu jsem viděl že použili proměnnou `ansible_architecture` z ansible facts což je dobrý nápad. Problém byl že jsem to nastavoval na arm64 vps a ansible to má pojmenované aarch64 a repo tedy nefungovalo. Nejdříve mě napadlo použit jinou proměnnou a to `ansible_facts['kernel']` a cutnout poslední část která má architekturu cpu. Tohle řešení je ale celkem špatné protože jsem to dělal pomocí `ansible_facts['kernel'].split('-').2` a kdyby se změnila verze kernelu a nebyla by zde pomlčka tak by to nefungovalo. Nevím tedy jestli je zde vždy ta pomlčka `6.1.0-13-arm64` nebo jestli jsou releases jen s např. `6.1.0-arm64` ale nechtěl jsem to riskovat, bylo to takové ošklivé řešení. Jako další řešení mě napadlo přidat proměnou do inventory souboru s hostem ale tohle řešení se mi nelíbilo jelikož by to bylo pokaždé potřeba manuálně specifikovat a určitě by to šlo nějak automaticky. Jako finálni řešení mě napadlo mít v playbooku proměnnou která vezme hodnotu z `ansible_architecture` a pokud je zde `aarch64` tak to přepíše na `arch64` jinak to jen vezme hodnotu která tam je. Kouknul jsem se jak něco takového udělat a pak jsem si to upravil aby to fungovalo tak jak chci. Tímhle byl tedy problém vyřešen a vše fungovalo.

- Když jsem měl tasky pro intall dockeru done tak mě napadlo ještě udělat firewall přes ansible. Při přidávání tasků do playbooku to ale žačalo být celkem nepřehledné. Přemýšlel jsem jestli firewall udělat jako playbook nebo jako roles. Co jsem koukal tak role má být hlavně pro věci které jsou reusable jako install mysql. U firewallu by to mohlo být reusable ale zase každý host může mít jiná pravidla, ale to by asi šlo nějak vždy specifikovat přes variables. Rozhodl jsem se ale to udělat jako další playbook protože mi to v tuhle chvíli přišlo jednodušší. Pohledal jsem jak managovat iptables přes ansible a našel jsem na to `ansible.builtin.iptables` takže to jsem použil. Postupně přidat pravidla atd. bylo jednoduché ale chtěl jsem aby se dali nějak specifikovat všechna pravidal a pak je jen proloopovat. Udělal jsem si tedy variables kde se specifikuje port, chain, jump. Všechny pravidla se nastavují pro ipv4 i ipv6 nemám to udělané tak aby se dalo specifikovat jen jedno.

- Firewall problem. Jelikož vše musí být pro IPv4 i IPv6 tak se mi nechtělo vše psát dvakrát. Nějakou dobu mi trvalo než jsem to zprovoznil chtěl jsem udělat v podstatně nested for loop. V dokumentaci na loopy jsem našel `Iterating over nested lists` což vypadalo že je to co chci ale z nějakého důvodu to nevracelo tu hodnotu co jsem chtěl. Když jsem to používal tak jak to měli napsané v examplu pokaždé mi to hodilo error. Zjistil jsem že je potřeba to použít be závorek `"{{ item.1 }}"` i když v dokumenatci to mají jako `"{{ item[0] }}"`, to mi ale nefungovalo. Pak jsem chtěl použít firewall playbook uvnitř hlavního playbooku kde byl install dockeru, zjistil jsem že to ale nejde. Install dockeru jem tedy přesunul do vlastního playbooku a hlavní playbook nyní jen importuje ostatní playbooky.

- Firewall uložení. Nejdříve mě napadlo to udělat přes shell modul ale pak jsem našel že je na to přímo community module. Ukládání mi ale nefungovalo soubory byli prázdné. Zkusil jsem odstranit loopy co jsem přidal aby stačil jeden task na IPv4 i IPv6. Měl jsem tedy stejný kod jako mají v examplu a fungovalo to. Zkusil jsem tedy dále postupně přidávat co jsem tam měl já a přidal jsem `ip_version`. I když bylo nepravděpodobné že by to bylo tímhle tak jsem to zkusil a playbook stále fungoval. Problém tedy musel být někde v hodnotách co tam ten loop dávál i když podle toho co to psalo při behu to vypadalo správně. Zkusil jsem si přidat ansible debug a vypast hodnoty z loopu a to také fungovalo v pořádku. To mi přišlo divné a už mě moc nenapadlo v čem by tedy mohl být problém. Zkusil jsem odkomentovat původní část pro ukládání pravidel s loops a tentokrát vše fungovalo a firewall se uložil so souborů. To mi přišlo celkem hodně zvláštní. Pak jsem si ale vzpomněl že jsem při testovaní s `ansible.builtin.debug` zahlédl že tam bylo `path: " {{ item.path }}"` místo `path: "{{ item.path }}"` a opravil to ale nečekal jsem že by to něco změnilo. Zkusil jsem tedy mezeru znovu přidat a opět to nefungovalo, věděl jsem tedy že problém byl celou dobu v tom.

- Vetšinou pokuď mám podobný problém tak se snažím postupovat stějně. Pokud se mi to nepodaří nějak rychle fixnout tak to dám do nějakého nejvíc simple formátu. Posutpně pak přidávám věci dokud se to nerozbije a mohu pak zjistit přesně jaký krok to způsobil.

- Nyní jsem dokončil playbook pro docker a firewall měl jsem tedy takový funkční základ na kterém se dá dál stavět a zprovozňovat různé služby. Udělal jsem si repo na githubu a pushnul tam moji jsem dosavadní práci.

### Co by šlo udělat jinak

- Pro firewall by mi možná přišlo lepši mít soubor ve kterém jsou už napsaná pravidla a ten jen na server zkopírovat a načíst.

### Nedostatky
- Firewall playbook nekontroluje jestli se uživatel nelockoutnul. U modulu community.general.iptables_state jsem viděl že má přímo možnost na načtení pravidel s rollbackem. To by bylo zajimavé dodat.

- Firewall je celkem basic, v mých variables není možnost nastavit třeba access jen z nějaké IP.

- Firewall playbook nemaže chainy.
