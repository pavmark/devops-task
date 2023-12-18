# Devops task
## About
Je zde několik playbooku které importuje hlavní playbook ve složce playbooks.


## Stage 1 - Základní setup VPS, Install dockeru

### Thought Process
- Nejdříve jsem se rozhodl podívat na ansible jelikož je to takový backbone tohoto projektu. S ansiblem mám malinko zkušenosti, napsal jsem si pár jednoduchých playbooku. Potřeboval jsem se o tom ale více naučit. Kouknul jsem tedy na pár videí, guidu a dokumentaci. Mám v plánu se ještě víde podívat na loopy a proměnné protože ty jsou hodně potřeba a často se u toho zaseknu a bere to čas.

- Pro začátek jsem kouknul jak to nějak organizovat a udělal podle toho pár složek i když některé jsou zatím nevyužité.

- Jako první jsem udělal playbook na install potřebných packagů a dockeru. To bylo celkem jednoduché jen jsem se na chvilku zasekl na přidávání repa. U přidáni je potřeba specifikovat architekturu, u jednoho guidu jsem viděl že použili proměnnou `ansible_architecture` z ansible facts což je dobrý nápad. Problém byl že jsem to nastavoval na arm64 vps a ansible to má pojmenované aarch64 a repo tedy nefungovalo. Nejdříve mě napadlo použit jinou proměnnou a to `ansible_facts['kernel']` a cutnout poslední část která má architekturu cpu. Tohle řešení je ale celkem špatné protože jsem to dělal pomocí `ansible_facts['kernel'].split('-').2` a kdyby se změnila verze kernelu a nebyla by zde pomlčka tak by to nefungovalo. Nevím tedy jestli je zde vždy ta pomlčka `6.1.0-13-arm64` nebo jestli jsou releases jen s např. `6.1.0-arm64` ale nechtěl jsem to riskovat, bylo to takové ošklivé řešení. Jako další řešení mě napadlo přidat proměnou do inventory souboru s hostem ale tohle řešení se mi nelíbilo jelikož by to bylo pokaždé potřeba manuálně specifikovat a určitě by to šlo nějak automaticky. Jako finálni řešení mě napadlo mít v playbooku proměnnou která vezme hodnotu z `ansible_architecture` a pokud je zde `aarch64` tak to přepíše na `arch64` jinak to jen vezme hodnotu která tam je. Kouknul jsem se jak něco takového udělat a pak jsem si to upravil aby to fungovalo tak jak chci. Tímhle byl tedy problém vyřešen a vše fungovalo.

- Když jsem měl tasky pro install dockeru done tak mě napadlo ještě udělat firewall přes ansible. Při přidávání tasků do playbooku to ale žačalo být celkem nepřehledné. Přemýšlel jsem jestli firewall udělat jako playbook nebo jako roles. Co jsem koukal tak role má být hlavně pro věci které jsou reusable jako install mysql. U firewallu by to mohlo být reusable ale zase každý host může mít jiná pravidla, ale to by asi šlo nějak vždy specifikovat přes variables. Rozhodl jsem se ale to udělat jako další playbook protože mi to v tuhle chvíli přišlo jednodušší. Pohledal jsem jak managovat iptables přes ansible a našel jsem na to `ansible.builtin.iptables` takže to jsem použil. Postupně přidat pravidla atd. bylo jednoduché ale chtěl jsem aby se dali nějak specifikovat všechna pravidal a pak je jen proloopovat. Udělal jsem si tedy variables kde se specifikuje port, chain, jump. Všechny pravidla se nastavují pro ipv4 i ipv6 nemám to udělané tak aby se dalo specifikovat jen jedno.

- Firewall problem. Jelikož vše musí být pro IPv4 i IPv6 tak se mi nechtělo vše psát dvakrát. Nějakou dobu mi trvalo než jsem to zprovoznil chtěl jsem udělat v podstatně nested for loop. V dokumentaci na loopy jsem našel `Iterating over nested lists` což vypadalo že je to co chci ale z nějakého důvodu to nevracelo tu hodnotu co jsem chtěl. Když jsem to používal tak jak to měli napsané v examplu pokaždé mi to hodilo error. Zjistil jsem že je potřeba to použít be závorek `"{{ item.1 }}"` i když v dokumenatci to mají jako `"{{ item[0] }}"`. Pak jsem chtěl použít firewall playbook uvnitř hlavního playbooku kde byl install dockeru, zjistil jsem že to ale nejde. Install dockeru jem tedy přesunul do vlastního playbooku a hlavní playbook nyní jen importuje ostatní playbooky.

- Firewall uložení. Nejdříve mě napadlo to udělat přes shell modul ale pak jsem našel že je na to přímo community module. Ukládání mi ale nefungovalo soubory byli prázdné. Zkusil jsem odstranit loopy co jsem přidal aby stačil jeden task na IPv4 i IPv6. Měl jsem tedy stejný kod jako mají v examplu a fungovalo to. Zkusil jsem tedy dále postupně přidávat co jsem tam měl já a přidal jsem `ip_version`. I když bylo nepravděpodobné že by to bylo tímhle tak jsem to zkusil a playbook stále fungoval. Problém tedy musel být někde v hodnotách co tam ten loop dávál i když podle toho co to psalo při behu to vypadalo správně. Zkusil jsem si přidat ansible debug a vypsat hodnoty z loopu a to také fungovalo v pořádku. To mi přišlo divné a už mě moc nenapadlo v čem by tedy mohl být problém. Zkusil jsem odkomentovat původní část pro ukládání pravidel s loops a tentokrát vše fungovalo a firewall se uložil so souborů. To mi přišlo celkem hodně zvláštní. Pak jsem si ale vzpomněl že jsem při testovaní s `ansible.builtin.debug` zahlédl že tam bylo `path: " {{ item.path }}"` místo `path: "{{ item.path }}"` a opravil to ale nečekal jsem že by to něco změnilo. Zkusil jsem tedy mezeru znovu přidat a opět to nefungovalo, věděl jsem tedy že problém byl celou dobu v tom.

- Vetšinou pokuď mám podobný problém tak se snažím postupovat stějně. Pokud se mi to nepodaří nějak rychle fixnout tak to dám do nějakého nejvíc simple formátu. Posutpně pak přidávám věci dokud se to nerozbije a mohu pak zjistit přesně jaký krok to způsobil.

- Nyní jsem dokončil playbook pro docker a firewall měl jsem tedy takový funkční základ na kterém se dá dál stavět a zprovozňovat různé služby. Udělal jsem si repo na githubu a pushnul tam moji dosavadní práci.

### Co by šlo udělat jinak

- Pro firewall by mi možná přišlo lepši mít soubor ve kterém jsou už napsaná pravidla a ten jen na server zkopírovat a načíst.

### Nedostatky
- Firewall playbook nekontroluje jestli se uživatel nelockoutnul. U modulu community.general.iptables_state jsem viděl že má přímo možnost na načtení pravidel s rollbackem. To by bylo zajimavé dodat.

- Firewall je celkem basic, v mých variables není možnost nastavit třeba access jen z nějaké IP.

- Firewall playbook nemaže chainy.

- Playbook počítá s tím že se vše instaluje na fresh debian based vps. Upgradují se všechny package a používá se apt modul.

## Stage 2 - Prometheus

- Nyní začnu dělat postupně jednotlivé tasky. Napadlo mě si tam prostě zkopírovat docker compose ale existují community modules přímo na docker tak jsem použil přímo community.docker.docker_container.

- Udělal jsem si playbook na prometheus. Rozhodoval jsem se jestli použít bind mount nebo volumes pro persistent storage. Volumes ale co si pamatuji mají trochu lepší performance a kdyby to mělo pak někdy hodně dat tak by to třeba šlo poznat. S volumes taky nemusím řesit složku pro to. Udělal jsem si teda named volume aby šlo jednoduše poznat.

- Teď jsem musel zjistit jak používat ten docker module. Vyzkoušel jsem to podle příkladu co tam mají a na tom stavěl dál. 

- Na prometheus jsem použil image od bitnami aby to bylo debian based. Přemýšlel jsem jaký tag picknout tak jsem si přečetl jejich docs jaký systém v tom mají. Nakonec jsem picknu prostě speficific verzi. Přemýšlel jsem nad picknutim "2" že by to dostávalo minor upgrady. V nekterých programech ale i minor upgrade vše rozbije a nevím jak to má prometheus tak jsem tam nechal na specific verzi.

- U kontejneru jsem nastavil logdriver na journald protože jsem to nikdy nemenil a zajímalo mě ja k to s tím funguje. Nic extra prostě to jde videt v hlavním logu a můž filtrovat podle jména containeru. Pořád můžu také použivat docker log.

- Na chvilku mě při vytváření volume zmátlo label. Myslel jsem že to pojmenuje ten volume. Pak jsem ale koukl do docker dokumentace on má vlastně docker labels na těch věcech když se dá inspect a tam si to můžu přidat. Pak jsem v docs ansible modulu našel že to pro volume specifikuje source.

- Pak jsem zkoumal co dělá "consistency" nastavní co byla jako možnost v ansible modulu. To ale co jsem koukal je něco starého co už ani není v docker docs.

- Nyní jsem potřeboval do promethea dostat vlastní config. Configs pro kontejnery jsem se rozhodl dávat do /etc/docker a přidal jsem do playbooku část aby to checkovalo že tam ta složka je případně přidalo. 

- To kopírováni configu jsem dal do playbooku co instaluje docker. Pak jsem to ale dal přímo do playbooku pro ten daný service protože to je jednodušší s tím pracovat když člověk něco mění a používa jen ten jeden playbook.

- Upravil jsem ansible-lint config aby to ignorovalo složku s configama pro služby protože to na mě křičelo že to je špatně.

- Podle docks jsem našel kam mountnout ten config.

- Přes curl jsem zkusil dostat data z promethe ale při verbose modu to bylo stuck na "Trying 127.0.0.1". Kouknul jsem na FW a došlo mi že jsem udělal oopise a nepovolil věci z local interfacu. Upravil jsem FW playbook a pak to fungovalo. 

- Prometheus jsem pak hodil at posloucha veřejně a ne na localhostu protože to je rychlejší checkovat. Pak to buď omezím opět na localhost nebo ten port povolím jen z mé IP.

- Pak byl issue že pri znovu zkopírovaní toho configu se neupdatoval v kontejneru. Zjistil jsem že když to je bind mount na soubor tak podle toho jak se edituje tak se to nemusí změnit protože to ukazuje na inode. Pokud by to mountovalo celou složku tak by to issue nebyl. Nastavil jsem v playbooku aby se ten kontejner pokaždé restartoval a pak to config načítalo.

- Přidání exporteru. Zde jsem přidal node exporter podle dokumentace aby to bralo metriky z hosta i když to je v kontejneru. Chtěl jsem nastavit aby to poslouchalo jen na localhostu ale to se mi nepodařilo najít jak specifikovat. Když to nepoužíva host network tak to jde normálně přes ports ale tady ne. Podle mě se to asi musí natavit přímo když se buildi ten kontejner že to ma exposnout na localhostu. Co jsem ale koukal tak tam se dá nastavit jen PORT a ne IP tak idk. Tady to ale blokuje FW takže z venčí se tam nikdo nedostane tak jsem to tak nechal. 

- Problém se scrapováním. Měl jsem problém s tím jak to scrapovat když to používa host network a 127.0.0.1 je v kontejneru ten kontejner sám. Pamatoval jsem si že jsem podobný issue už jednou měl ale nevím jestli se mi ho podařilo vyřešit. Pamtoval jsem si že existuje něco jako "host.docker.internal: [host-gateway]" a když to dám do extra hosts tak by přes to mělo jít scrapovat protože to ukazuje na ten actual host na kterem ten kontejner je. V ansible playbooku mi to ale nešlo přidat protože to není valid IP. Zkusil jsem si udělat compose na vps jestli to fakt funguje nebo ne. Nefungovalo mi to ale teď mě napadá že to mohlo být firewallem. 

- Jako další řešení toho problému jsem to zkusil nastavit podle guidu od grafany. Tam oba napojí na custom network ale nepoužívaji host network. Zkusil jsem to napojit na kontejner s host networkem ale to mi nečekaně nefungovalo. Nějak jsem myslel že to jako uděla extra sitovku pro ten kontejner a nějak to bude fungovat ale to nedává moc smysl když to prostě používa network hosta.

- Jelikož jsem nemohl nemohl přijít jak to scrapovat když je používat host network tak jsem se rozhodl prostě jít podle grafana guidu a nemít správné monitorování host networku.

- Dnes jsem nad tím ale přemýšlel že to musí jit nějak jednoduše udělat protože spousta služeb je přece jen na localhostu tak to by byla velká limitace. V těch forum postech na kterých jsem to předtím hledal jsem zjstil že ten host internal akorát ukazuje na gateway. Gateway vlastně bude to VPS takže to by mělo jit scrapovat tak. Udělal jsem quick google search pro ověření a bylo to tak. Nevím proč jem to tak neudělal předtím když jsem to četl ale asi se mi nelíbilo že bez toho docker internal to jako není dynamic. Já si ale může udělat vlastní docker network kde vždy budu vědět jaká je IP toho gatewaye tak idk proč mě to nenapadlo hned. 

- Udělal jsem si tedy vlastní docker network kde jsem specifikoval subnet atd. pak jsem na FW povolil ten rozsah a v prometheu zmenil target na ten gateway. Tohle krásně fungovalo takže tenhle issue byl resolved.

## Stage 3 - Nginx

- Jako další byl na řadě nginx. S nginx jsem nikdy nepracoval tak jsem koukl na jejich beginner guide a docker guide. Udělal jsem basic setup podle guidu a to fungovalo. Udělal jsem si složku web vedle playbooku a hodil tam simple web na test. Na serveru jsem udělal složku na web /var/www a web zkopíroval. To jsem pak bind mountul do kontejneru.

- Teď jsem potřeboval udělat vlastní config a hodit to do nginx. Ten config jsem udělal podle jejich guidu a opět bind montnul do kontejneru. To ale nefungovalo, kouknul jsem do logu a chybělo tam "events {}" tak jsem to dodal a už to frčelo.

- Kopírováni webu jsem dělal přes rsync ansible modul s delete aby to bylo 1:1 protože tohle se může často měnit a můžou se dělat další složky atd. Nginx mi ale pak vracel 403. Zkusil jsem změnit vlastníka složky na www-data jestli to něco udělá ale nic. Kouknul jsem pak do kontejneru a tam to jede vše přes roota takže jsem to vrátil zpět. Ono to přestalo fungovat nějak mezi pár změnami takže jsem nebyl úplně sure čím to bylo. Odebral jsem tedy bind mounty a postupně zkoušel přidávat. Při odbraném mountu jem koukl do kontejneru jaké to má mít správně práva. Porovnal jsem to s právama na serveru a všiml jsem si že jsem na serveru omylem změnil i práva složky místo jen souborů. To jsem opravil a už to fungovalo s vlastním configem a webem.

- Scrapovani metrics z nginx. Tady žádny issue nebyl. Udělal jsem to podle guidu a použil "nginx-prometheus-exporter". Na nginx-webu jem přidal stub-metrics dočasně to hodil na localhost port a přes curl testnul že to něco vrací. To jsem pak dal pryč a do exporteru jsem dal interni dns dockeru. To jsem přidal do promethea a vše krásne fungovalo.

- Proxy jsem opět nastavil podle jejich guidu a z vetšiny zkopíroval to co už jsem měl. Na proxy jsem udělal new playbook aby to bylo oddělené od webu.

- Bylo potřeba už jen přidat cachovani a monitoring. Na cachovani jsem našel od nginxu setup tak jsem to zkopíroval. Otestoval jsem že opakované zobrazení webu má reponse jen v logu proxy. Pak jsem zkusil nějakou random uri a v logu webu jsem ten request viděl i na web kontejenru. Koukl jsem pak ještě co to nastavení proxy vlastně dělá abych to jen hloupě nekopíroval.

- Rebuildnul jsem pak hetzner vps abych testnul že to vše funguje jako celek a vše bylo ok.

- Vzpomněl jsem si ještě že ty proxy a web servery vetšinou advertisuji svojí verzi. Ověřil jsem to přes firefox inspectnuti a bylo to tak. Kouknul jsem jak a vypnul jsem to pro top security trough obscurity. Nastaveni ngixnu bylo teda celkem bez problémů.

### Co by šlo zlepšit
- Ten config nginx je hodně basic a není to nastaven třeba pro víc domén.

## Stage 3.5 - Docker metrics

- Došlo mi že jsem špatně pochopil to "Pouzijte Prometheus a prislusne exportery ke sberu metrik z ostatnich VM/kontejneru" že to má monitorovat metrics tech služeb v tom kontejenru. Podle docker docs jsem teda udělal config, zapnul metrics a přidal scrape target do promethea. Jen jsem upravil tu IP na ktere posloucha na IP gatewaye pro monitoring network.