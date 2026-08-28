class CatFact {
  final Map<String, String> translations;

  const CatFact(this.translations);

  String text(String languageCode) {
    return translations[languageCode] ??
        translations['en'] ??
        translations['fi'] ??
        '';
  }
}

const List<CatFact> catFacts = [
  CatFact({
    'fi': 'Kissat nukkuvat usein 12–16 tuntia vuorokaudessa.',
    'en': 'Cats often sleep 12–16 hours a day.',
  }),
  CatFact({
    'fi': 'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'en': 'A cat’s whiskers are highly sensitive sensory organs.',
  }),
  CatFact({
    'fi': 'Jokaisella kissalla on yksilöllinen nenän kuvio.',
    'en': 'Every cat has a unique nose pattern.',
  }),
  CatFact({
    'fi': 'Kissat voivat kuulla erittäin korkeita ääniä.',
    'en': 'Cats can hear very high-frequency sounds.',
  }),
  CatFact({
    'fi': 'Useimpien kissojen kynnet ovat sisäänvedettävät.',
    'en': 'Most cats have retractable claws.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät häntäänsä tasapainon apuna.',
    'en': 'Cats use their tails to help with balance.',
  }),
  CatFact({
    'fi': 'Hidas silmien räpytys voi olla kissan ystävällinen tervehdys.',
    'en': 'A slow blink can be a friendly greeting from a cat.',
  }),
  CatFact({
    'fi': 'Kissat ovat luonnostaan uteliaita eläimiä.',
    'en': 'Cats are naturally curious animals.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät hajuaistiaan tutkiessaan ympäristöään.',
    'en': 'Cats use their sense of smell to explore their surroundings.',
  }),
  CatFact({
    'fi': 'Kissan kielessä on pieniä taaksepäin suuntautuvia papilleja.',
    'en': 'A cat’s tongue has tiny backward-facing papillae.',
  }),
  CatFact({
    'fi': 'Kissat pesevät itseään usein pitääkseen turkkinsa puhtaana.',
    'en': 'Cats groom themselves frequently to keep their fur clean.',
  }),
  CatFact({
    'fi': 'Kissan pupillit voivat muuttua hyvin kapeiksi tai suuriksi.',
    'en': 'A cat’s pupils can become very narrow or very large.',
  }),
  CatFact({
    'fi': 'Kissat ovat usein aktiivisimmillaan aamun ja illan hämärässä.',
    'en': 'Cats are often most active around dawn and dusk.',
  }),
  CatFact({
    'fi': 'Kissat voivat hypätä monta kertaa oman pituutensa verran.',
    'en': 'Cats can jump several times their own body length.',
  }),
  CatFact({
    'fi': 'Kissan häntä voi kertoa paljon sen mielialasta.',
    'en': 'A cat’s tail can communicate a lot about its mood.',
  }),
  CatFact({
    'fi': 'Kissan pehmeät tassut auttavat sitä liikkumaan hiljaa.',
    'en': 'A cat’s soft paws help it move quietly.',
  }),
  CatFact({
    'fi': 'Kissan kehräys voi tuntua matalana värinänä.',
    'en': 'A cat’s purr can feel like a low vibration.',
  }),
  CatFact({
    'fi': 'Kissat oppivat tunnistamaan tuttuja ääniä.',
    'en': 'Cats can learn to recognize familiar sounds.',
  }),
  CatFact({
    'fi': 'Kissan hajuaisti on ihmisen hajuaistia voimakkaampi.',
    'en': 'A cat’s sense of smell is stronger than a human’s.',
  }),
  CatFact({
    'fi': 'Kissat voivat ilmaista itseään monilla erilaisilla äänillä.',
    'en': 'Cats can communicate using many different sounds.',
  }),
  CatFact({
    'fi': 'Aikuinen kissa maukuu usein ihmisille enemmän kuin toisille kissoille.',
    'en': 'Adult cats often meow to humans more than to other cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää viiksiään arvioidakseen kapeita tiloja.',
    'en': 'Cats can use their whiskers to judge narrow spaces.',
  }),
  CatFact({
    'fi': 'Kissan etutassuissa on yleensä viisi varvasta.',
    'en': 'A cat usually has five toes on each front paw.',
  }),
  CatFact({
    'fi': 'Kissan takatassuissa on yleensä neljä varvasta.',
    'en': 'A cat usually has four toes on each back paw.',
  }),
  CatFact({
    'fi': 'Joillakin kissoilla on tavallista enemmän varpaita.',
    'en': 'Some cats have more toes than usual.',
  }),
  CatFact({
    'fi': 'Kissat näkevät hämärässä ihmisiä paremmin.',
    'en': 'Cats see better than humans in dim light.',
  }),
  CatFact({
    'fi': 'Kissat eivät kuitenkaan näe täydellisessä pimeydessä.',
    'en': 'Cats still cannot see in complete darkness.',
  }),
  CatFact({
    'fi': 'Kissan silmät ovat suuret suhteessa sen pään kokoon.',
    'en': 'A cat’s eyes are large relative to its head size.',
  }),
  CatFact({
    'fi': 'Kissat reagoivat nopeasti liikkuviin kohteisiin.',
    'en': 'Cats react quickly to moving objects.',
  }),
  CatFact({
    'fi': 'Kissan korvat voivat kääntyä äänen suuntaan.',
    'en': 'A cat’s ears can rotate toward a sound.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia päivittäisiä rutiineja nopeasti.',
    'en': 'Cats can learn daily routines quickly.',
  }),
  CatFact({
    'fi': 'Monet kissat pitävät lämpimistä nukkumapaikoista.',
    'en': 'Many cats enjoy warm places to sleep.',
  }),
  CatFact({
    'fi': 'Kissat etsivät usein korkeita paikkoja tarkkaillakseen ympäristöään.',
    'en': 'Cats often seek high places to observe their surroundings.',
  }),
  CatFact({
    'fi': 'Raapiminen auttaa kissaa hoitamaan kynsiään.',
    'en': 'Scratching helps a cat maintain its claws.',
  }),
  CatFact({
    'fi': 'Raapiminen voi myös olla tapa merkitä aluetta.',
    'en': 'Scratching can also be a way to mark territory.',
  }),
  CatFact({
    'fi': 'Kissan tassuissa on tuoksurauhasia.',
    'en': 'Cats have scent glands in their paws.',
  }),
  CatFact({
    'fi': 'Kissat voivat hieroa päätään ihmistä vasten jättääkseen tuttua tuoksua.',
    'en': 'Cats may rub their heads against people to leave familiar scent.',
  }),
  CatFact({
    'fi': 'Kissan kehon kieli on tärkeä osa sen viestintää.',
    'en': 'A cat’s body language is an important part of communication.',
  }),
  CatFact({
    'fi': 'Kissat venyttelevät usein levon jälkeen.',
    'en': 'Cats often stretch after resting.',
  }),
  CatFact({
    'fi': 'Kissan turkki auttaa säätelemään ruumiinlämpöä.',
    'en': 'A cat’s fur helps regulate body temperature.',
  }),
  CatFact({
    'fi': 'Kissat vaihtavat turkkiaan vuodenaikojen mukaan.',
    'en': 'Cats shed and renew their coats with the seasons.',
  }),
  CatFact({
    'fi': 'Säännöllinen harjaus voi vähentää irtokarvoja.',
    'en': 'Regular brushing can reduce loose fur.',
  }),
  CatFact({
    'fi': 'Kissat ovat taitavia tasapainoilijoita.',
    'en': 'Cats are skilled at balancing.',
  }),
  CatFact({
    'fi': 'Kissan sisäkorva auttaa tasapainon ylläpitämisessä.',
    'en': 'A cat’s inner ear helps maintain balance.',
  }),
  CatFact({
    'fi': 'Kissat voivat kääntää vartaloaan ilmassa.',
    'en': 'Cats can twist their bodies in the air.',
  }),
  CatFact({
    'fi': 'Kissan refleksit ovat yleensä erittäin nopeat.',
    'en': 'A cat’s reflexes are generally very fast.',
  }),
  CatFact({
    'fi': 'Leikki auttaa kissaa harjoittamaan metsästyskäyttäytymistä.',
    'en': 'Play helps a cat practice hunting behavior.',
  }),
  CatFact({
    'fi': 'Monet kissat pitävät leluista, jotka liikkuvat kuin pieni saalis.',
    'en': 'Many cats enjoy toys that move like small prey.',
  }),
  CatFact({
    'fi': 'Kissat tarvitsevat ympäristöönsä virikkeitä.',
    'en': 'Cats need stimulation in their environment.',
  }),
  CatFact({
    'fi': 'Raapimapuu voi tarjota kissalle liikuntaa ja virikkeitä.',
    'en': 'A scratching tree can provide exercise and enrichment.',
  }),

  // 51–100

  CatFact({
    'fi': 'Kissat voivat oppia tunnistamaan oman nimensä.',
    'en': 'Cats can learn to recognize their own names.',
  }),
  CatFact({
    'fi': 'Jokaisen kissan persoonallisuus on erilainen.',
    'en': 'Every cat has a different personality.',
  }),
  CatFact({
    'fi': 'Kissat voivat muodostaa vahvoja siteitä ihmisiin.',
    'en': 'Cats can form strong bonds with people.',
  }),
  CatFact({
    'fi': 'Jotkut kissat pitävät vedestä enemmän kuin toiset.',
    'en': 'Some cats enjoy water more than others.',
  }),
  CatFact({
    'fi': 'Kissat voivat juoda vettä erittäin nopeasti.',
    'en': 'Cats can drink water very quickly.',
  }),
  CatFact({
    'fi': 'Kissan kuulo auttaa sitä havaitsemaan pienenkin liikkeen.',
    'en': 'A cat’s hearing helps detect even small movements.',
  }),
  CatFact({
    'fi': 'Kissat voivat nukkua useissa erilaisissa asennoissa.',
    'en': 'Cats can sleep in many different positions.',
  }),
  CatFact({
    'fi': 'Kissat voivat nukkua käpertyneenä lämmön säilyttämiseksi.',
    'en': 'Cats may curl up while sleeping to conserve warmth.',
  }),
  CatFact({
    'fi': 'Rentoutunut kissa voi nukkua selällään.',
    'en': 'A relaxed cat may sleep on its back.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät paljon aikaa ympäristön tarkkailuun.',
    'en': 'Cats spend a lot of time observing their surroundings.',
  }),
  CatFact({
    'fi': 'Kissan korvien asento voi kertoa sen mielialasta.',
    'en': 'The position of a cat’s ears can reveal its mood.',
  }),
  CatFact({
    'fi': 'Pystyssä oleva häntä voi olla ystävällinen tervehdys.',
    'en': 'An upright tail can be a friendly greeting.',
  }),
  CatFact({
    'fi': 'Kissat voivat kommunikoida myös tuoksujen avulla.',
    'en': 'Cats can also communicate through scents.',
  }),
  CatFact({
    'fi': 'Kissat voivat tunnistaa tuttuja paikkoja niiden hajujen perusteella.',
    'en': 'Cats can recognize familiar places by their smells.',
  }),
  CatFact({
    'fi': 'Kissat pitävät usein omista turvallisista piilopaikoistaan.',
    'en': 'Cats often enjoy having their own safe hiding places.',
  }),
  CatFact({
    'fi': 'Laatikot voivat tuntua kissasta turvallisilta piilopaikoilta.',
    'en': 'Boxes can feel like safe hiding places to cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat viettää paljon aikaa ikkunasta katsellen.',
    'en': 'Cats can spend a lot of time watching through windows.',
  }),
  CatFact({
    'fi': 'Linnut ja pienet liikkuvat kohteet kiinnostavat monia kissoja.',
    'en': 'Birds and small moving objects interest many cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia käyttämään erilaisia leluja.',
    'en': 'Cats can learn how to use different toys.',
  }),
  CatFact({
    'fi': 'Ruoka voi olla tehokas palkinto kissan koulutuksessa.',
    'en': 'Food can be an effective reward in cat training.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia yksinkertaisia temppuja.',
    'en': 'Cats can learn simple tricks.',
  }),
  CatFact({
    'fi': 'Kissat ovat usein tarkkoja puhtaudestaan.',
    'en': 'Cats are often very concerned with cleanliness.',
  }),
  CatFact({
    'fi': 'Kissan hiekkalaatikon puhtaus on sille tärkeää.',
    'en': 'A clean litter box is important to a cat.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla herkkiä muutoksille ympäristössään.',
    'en': 'Cats can be sensitive to changes in their environment.',
  }),
  CatFact({
    'fi': 'Uudet ihmiset voivat vaatia kissalta aikaa tottua.',
    'en': 'Cats may need time to get used to new people.',
  }),
  CatFact({
    'fi': 'Rauhallinen lähestyminen voi auttaa kissaa tuntemaan olonsa turvalliseksi.',
    'en': 'A calm approach can help a cat feel safe.',
  }),
  CatFact({
    'fi': 'Kissat pitävät usein ennakoitavista rutiineista.',
    'en': 'Cats often enjoy predictable routines.',
  }),
  CatFact({
    'fi': 'Kissan ruokailuaika voi muodostua tärkeäksi osaksi päivää.',
    'en': 'Mealtime can become an important part of a cat’s day.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin kärsivällisiä tarkkailijoita.',
    'en': 'Cats can be very patient observers.',
  }),
  CatFact({
    'fi': 'Kissan metsästyskäyttäytyminen voi näkyä myös leikissä.',
    'en': 'A cat’s hunting behavior can also appear during play.',
  }),
  CatFact({
    'fi': 'Kissat voivat väijyä lelua ennen hyökkäystä.',
    'en': 'Cats may stalk a toy before pouncing.',
  }),
  CatFact({
    'fi': 'Kissan takajalat ovat voimakkaat hyppäämistä varten.',
    'en': 'A cat’s hind legs are powerful for jumping.',
  }),
  CatFact({
    'fi': 'Kissat voivat kiivetä erittäin taitavasti.',
    'en': 'Cats can climb very skillfully.',
  }),
  CatFact({
    'fi': 'Kaikki kissat eivät kuitenkaan pidä samoista korkeuksista.',
    'en': 'Not all cats enjoy the same heights.',
  }),
  CatFact({
    'fi': 'Kissan leikki voi muuttua iän myötä.',
    'en': 'A cat’s play behavior can change with age.',
  }),
  CatFact({
    'fi': 'Pennut ovat yleensä hyvin leikkisiä.',
    'en': 'Kittens are usually very playful.',
  }),
  CatFact({
    'fi': 'Vanhemmat kissat voivat suosia rauhallisempaa toimintaa.',
    'en': 'Older cats may prefer calmer activities.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää tassujaan esineiden tutkimiseen.',
    'en': 'Cats can use their paws to explore objects.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla sekä itsenäisiä että seurallisia.',
    'en': 'Cats can be both independent and social.',
  }),
  CatFact({
    'fi': 'Jotkut kissat seuraavat omistajaansa huoneesta toiseen.',
    'en': 'Some cats follow their owners from room to room.',
  }),
  CatFact({
    'fi': 'Kissat voivat nauttia rauhallisesta puheesta.',
    'en': 'Cats may enjoy calm voices.',
  }),
  CatFact({
    'fi': 'Kissat tunnistavat usein tuttujen ihmisten ääniä.',
    'en': 'Cats often recognize familiar human voices.',
  }),
  CatFact({
    'fi': 'Kissan kehräys ei aina tarkoita vain onnellisuutta.',
    'en': 'A cat’s purr does not always mean happiness.',
  }),
  CatFact({
    'fi': 'Kissat voivat kehrätä erilaisissa tilanteissa.',
    'en': 'Cats can purr in different situations.',
  }),
  CatFact({
    'fi': 'Kissan viikset auttavat sitä aistimaan lähellä olevia asioita.',
    'en': 'A cat’s whiskers help it sense nearby objects.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät näköään ja kuuloaan yhdessä metsästyksessä.',
    'en': 'Cats use vision and hearing together when hunting.',
  }),
  CatFact({
    'fi': 'Kissan silmät voivat heijastaa valoa hämärässä.',
    'en': 'A cat’s eyes can reflect light in dim conditions.',
  }),
  CatFact({
    'fi': 'Kissat voivat havaita pieniä liikkeitä nopeasti.',
    'en': 'Cats can quickly notice small movements.',
  }),
  CatFact({
    'fi': 'Monet kissat pitävät aurinkoisista paikoista.',
    'en': 'Many cats enjoy sunny spots.',
  }),
  CatFact({
    'fi': 'Kissat voivat vaihtaa nukkumapaikkaansa päivän aikana.',
    'en': 'Cats may change sleeping places during the day.',
  }),
  CatFact({
    'fi': 'Turvallinen kotiympäristö auttaa kissaa rentoutumaan.',
    'en': 'A safe home environment helps a cat relax.',
  }),

  // 101–150

  CatFact({
    'fi': 'Kissat voivat muistaa kokemuksia pitkään.',
    'en': 'Cats can remember experiences for a long time.',
  }),
  CatFact({
    'fi': 'Kissat voivat yhdistää ääniä tiettyihin tapahtumiin.',
    'en': 'Cats can associate sounds with certain events.',
  }),
  CatFact({
    'fi': 'Monet kissat tunnistavat ruokapussin äänen.',
    'en': 'Many cats recognize the sound of their food bag.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia, mistä niiden ruoka tulee.',
    'en': 'Cats can learn where their food comes from.',
  }),
  CatFact({
    'fi': 'Kissat voivat odottaa omistajaansa tutun aikataulun mukaan.',
    'en': 'Cats may wait for their owners according to familiar schedules.',
  }),
  CatFact({
    'fi': 'Kissat voivat ilmaista kiinnostusta katseellaan.',
    'en': 'Cats can show interest through their gaze.',
  }),
  CatFact({
    'fi': 'Kissan rento asento kertoo usein turvallisuuden tunteesta.',
    'en': 'A relaxed posture often shows that a cat feels safe.',
  }),
  CatFact({
    'fi': 'Kissat voivat piiloutua, jos ne pelästyvät.',
    'en': 'Cats may hide when they become frightened.',
  }),
  CatFact({
    'fi': 'Kissat tarvitsevat aikaa tottuakseen uusiin tilanteisiin.',
    'en': 'Cats need time to adjust to new situations.',
  }),
  CatFact({
    'fi': 'Jotkut kissat ovat rohkeampia kuin toiset.',
    'en': 'Some cats are braver than others.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin tarkkoja siitä, missä ne nukkuvat.',
    'en': 'Cats can be very selective about where they sleep.',
  }),
  CatFact({
    'fi': 'Pehmeät alustat ovat monien kissojen suosikkeja.',
    'en': 'Soft surfaces are favorites of many cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat nauttia lämpimästä peitosta.',
    'en': 'Cats may enjoy a warm blanket.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää ihmistä lämpimänä nukkumapaikkana.',
    'en': 'Cats may use a human as a warm sleeping place.',
  }),
  CatFact({
    'fi': 'Kissat voivat osoittaa luottamusta nukkumalla lähellä ihmistä.',
    'en': 'Cats may show trust by sleeping near a person.',
  }),
  CatFact({
    'fi': 'Kissan vatsan näyttäminen voi olla merkki luottamuksesta.',
    'en': 'Showing the belly can be a sign of trust.',
  }),
  CatFact({
    'fi': 'Vatsan näyttäminen ei aina tarkoita, että kissa haluaa vatsan rapsutusta.',
    'en': 'Showing the belly does not always mean a cat wants belly rubs.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää erilaisia maukumisia eri tilanteissa.',
    'en': 'Cats can use different meows in different situations.',
  }),
  CatFact({
    'fi': 'Jotkut kissat ovat luonnostaan hyvin puheliaita.',
    'en': 'Some cats are naturally very vocal.',
  }),
  CatFact({
    'fi': 'Toiset kissat ovat lähes hiljaisia.',
    'en': 'Other cats are almost silent.',
  }),
  CatFact({
    'fi': 'Kissat voivat viestiä myös kehonsa asennolla.',
    'en': 'Cats can also communicate through body posture.',
  }),
  CatFact({
    'fi': 'Pörröinen häntä voi olla merkki voimakkaasta tunnetilasta.',
    'en': 'A puffed-up tail can signal a strong emotional state.',
  }),
  CatFact({
    'fi': 'Kissan selkä voi kaartua sen yrittäessä näyttää suuremmalta.',
    'en': 'A cat may arch its back to appear larger.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla erittäin nopeita lyhyillä matkoilla.',
    'en': 'Cats can be extremely fast over short distances.',
  }),
  CatFact({
    'fi': 'Kissan vartalo on rakennettu nopeisiin ja ketteriin liikkeisiin.',
    'en': 'A cat’s body is built for quick and agile movements.',
  }),
  CatFact({
    'fi': 'Kissat voivat liikkua lähes äänettömästi.',
    'en': 'Cats can move almost silently.',
  }),
  CatFact({
    'fi': 'Kissan tassunpohjat pehmentävät askelia.',
    'en': 'The pads of a cat’s paws soften its steps.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää kynsiään kiipeämiseen.',
    'en': 'Cats can use their claws for climbing.',
  }),
  CatFact({
    'fi': 'Kynnet kasvavat jatkuvasti.',
    'en': 'A cat’s claws continue to grow.',
  }),
  CatFact({
    'fi': 'Raapiminen auttaa poistamaan kynsien ulompaa kerrosta.',
    'en': 'Scratching helps remove the outer layer of the claws.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin tarkkoja saaliin liikkeistä.',
    'en': 'Cats can pay close attention to prey movement.',
  }),
  CatFact({
    'fi': 'Leikkiminen voi auttaa sisäkissaa käyttämään energiaa.',
    'en': 'Playing can help an indoor cat use energy.',
  }),
  CatFact({
    'fi': 'Lyhyet leikkihetket voivat olla kissalle hyödyllisiä.',
    'en': 'Short play sessions can be beneficial for cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat kyllästyä samaan leluun.',
    'en': 'Cats can become bored with the same toy.',
  }),
  CatFact({
    'fi': 'Lelujen vaihtelu voi tehdä leikistä kiinnostavampaa.',
    'en': 'Rotating toys can make play more interesting.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia avaamaan yksinkertaisia ovia.',
    'en': 'Cats can learn to open simple doors.',
  }),
  CatFact({
    'fi': 'Jotkut kissat ovat erityisen taitavia ongelmanratkaisijoita.',
    'en': 'Some cats are especially skilled problem solvers.',
  }),
  CatFact({
    'fi': 'Kissat tutkivat usein uusia esineitä hajun avulla.',
    'en': 'Cats often investigate new objects by smell.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla epäluuloisia uusista asioista aluksi.',
    'en': 'Cats can be cautious around new things at first.',
  }),
  CatFact({
    'fi': 'Turvallinen tutustuminen auttaa kissaa hyväksymään muutoksia.',
    'en': 'Safe introductions can help cats accept changes.',
  }),
  CatFact({
    'fi': 'Kissat voivat pitää hiljaisista ympäristöistä.',
    'en': 'Cats may prefer quiet environments.',
  }),
  CatFact({
    'fi': 'Äkilliset kovat äänet voivat pelästyttää kissan.',
    'en': 'Sudden loud noises can frighten a cat.',
  }),
  CatFact({
    'fi': 'Kissat voivat etsiä suojaa ukkosen aikana.',
    'en': 'Cats may seek shelter during thunderstorms.',
  }),
  CatFact({
    'fi': 'Kissan kuulo on tärkeä osa sen ympäristön tarkkailua.',
    'en': 'A cat’s hearing is an important part of observing its environment.',
  }),
  CatFact({
    'fi': 'Kissat voivat liikuttaa korviaan toisistaan riippumatta.',
    'en': 'Cats can move their ears independently.',
  }),
  CatFact({
    'fi': 'Kissan korvat auttavat paikantamaan äänen suunnan.',
    'en': 'A cat’s ears help locate the direction of sounds.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla erityisen aktiivisia iltaisin.',
    'en': 'Cats can be especially active in the evening.',
  }),
  CatFact({
    'fi': 'Päivän rytmi voi vaihdella kissan elämäntavan mukaan.',
    'en': 'A cat’s daily rhythm can vary depending on its lifestyle.',
  }),
  CatFact({
    'fi': 'Kissat voivat viettää paljon aikaa lepäämällä.',
    'en': 'Cats can spend a large amount of time resting.',
  }),
  CatFact({
    'fi': 'Lepo auttaa kissaa palautumaan aktiivisista hetkistä.',
    'en': 'Rest helps a cat recover from active moments.',
  }),

  // 151–200

  CatFact({
    'fi': 'Kissat voivat vaihtaa asentoa monta kertaa unen aikana.',
    'en': 'Cats can change position many times while sleeping.',
  }),
  CatFact({
    'fi': 'Kissan uniasento voi riippua lämpötilasta.',
    'en': 'A cat’s sleeping position can depend on temperature.',
  }),
  CatFact({
    'fi': 'Kissat voivat hakeutua viileään paikkaan kuumalla säällä.',
    'en': 'Cats may seek cooler places in hot weather.',
  }),
  CatFact({
    'fi': 'Kissat voivat hakeutua lämpimään paikkaan kylmällä säällä.',
    'en': 'Cats may seek warmer places in cold weather.',
  }),
  CatFact({
    'fi': 'Monet kissat pitävät auringonpaisteesta.',
    'en': 'Many cats enjoy sunshine.',
  }),
  CatFact({
    'fi': 'Kissat voivat tarkkailla maailmaa pitkään ikkunasta.',
    'en': 'Cats can watch the world through a window for a long time.',
  }),
  CatFact({
    'fi': 'Ikkunasta katselu voi tarjota kissalle virikkeitä.',
    'en': 'Watching through a window can provide enrichment for cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat kiinnostua hyönteisistä.',
    'en': 'Cats can be interested in insects.',
  }),
  CatFact({
    'fi': 'Nopeasti liikkuvat asiat herättävät usein kissan huomion.',
    'en': 'Fast-moving things often attract a cat’s attention.',
  }),
  CatFact({
    'fi': 'Kissat voivat väijyä ennen kuin ne hyppäävät.',
    'en': 'Cats may stalk before they pounce.',
  }),
  CatFact({
    'fi': 'Kissan hyppy alkaa usein voimakkaasta takajalkojen työnnöstä.',
    'en': 'A cat’s jump often begins with a powerful push from its hind legs.',
  }),
  CatFact({
    'fi': 'Kissat voivat laskeutua erittäin ketterästi.',
    'en': 'Cats can land very agilely.',
  }),
  CatFact({
    'fi': 'Kissat arvioivat etäisyyksiä ennen hyppäämistä.',
    'en': 'Cats estimate distances before jumping.',
  }),
  CatFact({
    'fi': 'Kissat voivat epäröidä, jos alusta tuntuu epävarmalta.',
    'en': 'Cats may hesitate if a surface feels unstable.',
  }),
  CatFact({
    'fi': 'Kissat pitävät usein tukevista kiipeilypaikoista.',
    'en': 'Cats often prefer sturdy climbing places.',
  }),
  CatFact({
    'fi': 'Korkeat tasot voivat tarjota kissalle turvallisuuden tunnetta.',
    'en': 'High platforms can provide cats with a sense of security.',
  }),
  CatFact({
    'fi': 'Kissat voivat tarkkailla muita eläimiä turvalliselta etäisyydeltä.',
    'en': 'Cats may observe other animals from a safe distance.',
  }),
  CatFact({
    'fi': 'Jotkut kissat ovat hyvin sosiaalisia.',
    'en': 'Some cats are very social.',
  }),
  CatFact({
    'fi': 'Jotkut kissat tarvitsevat enemmän omaa tilaa.',
    'en': 'Some cats need more personal space.',
  }),
  CatFact({
    'fi': 'Kissan persoonallisuus vaikuttaa siihen, kuinka se käyttäytyy ihmisten kanssa.',
    'en': 'A cat’s personality affects how it behaves with people.',
  }),
  CatFact({
    'fi': 'Kissat voivat muodostaa ystävyyssuhteita toisten kissojen kanssa.',
    'en': 'Cats can form friendships with other cats.',
  }),
  CatFact({
    'fi': 'Kaikki kissat eivät kuitenkaan halua jakaa tilaansa.',
    'en': 'Not all cats want to share their space.',
  }),
  CatFact({
    'fi': 'Kissat voivat tunnistaa toisensa tuoksujen avulla.',
    'en': 'Cats can recognize one another through scent.',
  }),
  CatFact({
    'fi': 'Kissat voivat hieroa toisiaan vahvistaakseen sosiaalisia siteitä.',
    'en': 'Cats may rub against each other to strengthen social bonds.',
  }),
  CatFact({
    'fi': 'Yhdessä nukkuvat kissat voivat tuntea olonsa turvalliseksi.',
    'en': 'Cats that sleep together may feel safe with each other.',
  }),
  CatFact({
    'fi': 'Kissat voivat hoitaa myös toistensa turkkia.',
    'en': 'Cats can groom each other.',
  }),
  CatFact({
    'fi': 'Kissan turkin väri ei yksin kerro sen persoonallisuudesta.',
    'en': 'A cat’s fur color alone does not determine its personality.',
  }),
  CatFact({
    'fi': 'Kissoilla on valtavasti erilaisia turkkikuvioita.',
    'en': 'Cats have a huge variety of coat patterns.',
  }),
  CatFact({
    'fi': 'Raidallinen turkki on yksi tavallisista kissakuvioista.',
    'en': 'Striped coats are one common cat pattern.',
  }),
  CatFact({
    'fi': 'Joillakin kissoilla on yksivärinen turkki.',
    'en': 'Some cats have solid-colored coats.',
  }),
  CatFact({
    'fi': 'Moniväriset turkit voivat muodostaa monimutkaisia kuvioita.',
    'en': 'Multicolored coats can form complex patterns.',
  }),
  CatFact({
    'fi': 'Kissan turkin pituus voi olla lyhyt tai pitkä.',
    'en': 'A cat’s coat can be short or long.',
  }),
  CatFact({
    'fi': 'Pitkäkarvaiset kissat tarvitsevat usein enemmän turkinhoitoa.',
    'en': 'Long-haired cats often need more coat care.',
  }),
  CatFact({
    'fi': 'Harjaaminen voi olla monelle kissalle miellyttävä hetki.',
    'en': 'Brushing can be enjoyable for many cats.',
  }),
  CatFact({
    'fi': 'Kaikki kissat eivät pidä samanlaisesta harjauksesta.',
    'en': 'Not all cats enjoy the same type of brushing.',
  }),
  CatFact({
    'fi': 'Kissat voivat ilmaista tyytyväisyyttä rentoutumalla.',
    'en': 'Cats can show contentment by relaxing.',
  }),
  CatFact({
    'fi': 'Rauhallinen kehräys voi kuulua tyytyväisen kissan ääniin.',
    'en': 'Gentle purring can be one sound of a content cat.',
  }),
  CatFact({
    'fi': 'Kissat voivat myös viestiä hiljaisuudella ja katseella.',
    'en': 'Cats can also communicate through silence and eye contact.',
  }),
  CatFact({
    'fi': 'Kissat ovat hyviä tarkkailemaan ihmisten käyttäytymistä.',
    'en': 'Cats are good at observing human behavior.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia, kuka yleensä antaa niille ruokaa.',
    'en': 'Cats can learn who usually gives them food.',
  }),
  CatFact({
    'fi': 'Kissat voivat odottaa tuttuja rutiineja.',
    'en': 'Cats can anticipate familiar routines.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia yhdistämään tietyn äänen ruokaan.',
    'en': 'Cats can learn to associate a particular sound with food.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin motivoituneita herkkujen avulla.',
    'en': 'Cats can be highly motivated by treats.',
  }),
  CatFact({
    'fi': 'Positiivinen palkitseminen voi auttaa kissan koulutuksessa.',
    'en': 'Positive rewards can help with cat training.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia tulemaan kutsusta.',
    'en': 'Cats can learn to come when called.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia käyttämään raapimapuuta.',
    'en': 'Cats can learn to use a scratching post.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia käyttämään valjaita vähitellen.',
    'en': 'Cats can gradually learn to use a harness.',
  }),
  CatFact({
    'fi': 'Jokainen kissa oppii omaan tahtiinsa.',
    'en': 'Every cat learns at its own pace.',
  }),
  CatFact({
    'fi': 'Kärsivällisyys on tärkeää kissan kanssa.',
    'en': 'Patience is important when working with cats.',
  }),
  CatFact({
    'fi': 'Kissat arvostavat usein mahdollisuutta tehdä omia valintoja.',
    'en': 'Cats often appreciate having choices.',
  }),
  CatFact({
    'fi': 'Turvallinen ympäristö auttaa kissaa näyttämään persoonallisuutensa.',
    'en': 'A safe environment helps a cat show its personality.',
  }),

  // 201–250

  CatFact({
    'fi': 'Kissat voivat olla hyvin leikkisiä myös aikuisina.',
    'en': 'Cats can remain very playful as adults.',
  }),
  CatFact({
    'fi': 'Leikki voi vahvistaa kissan ja ihmisen välistä suhdetta.',
    'en': 'Play can strengthen the bond between a cat and a person.',
  }),
  CatFact({
    'fi': 'Kissat voivat pitää erilaisista leikkityyleistä.',
    'en': 'Cats can enjoy different styles of play.',
  }),
  CatFact({
    'fi': 'Jotkut kissat pitävät sulkaleluista.',
    'en': 'Some cats enjoy feather toys.',
  }),
  CatFact({
    'fi': 'Jotkut kissat pitävät palloista.',
    'en': 'Some cats enjoy balls.',
  }),
  CatFact({
    'fi': 'Jotkut kissat pitävät leluhiiristä.',
    'en': 'Some cats enjoy toy mice.',
  }),
  CatFact({
    'fi': 'Kissat voivat kantaa pieniä leluja suussaan.',
    'en': 'Cats may carry small toys in their mouths.',
  }),
  CatFact({
    'fi': 'Kissat voivat tuoda leluja ihmiselle.',
    'en': 'Cats may bring toys to people.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia avaamaan kaappeja.',
    'en': 'Cats can learn to open cabinets.',
  }),
  CatFact({
    'fi': 'Uteliaisuus voi saada kissan tutkimaan uusia paikkoja.',
    'en': 'Curiosity can lead cats to explore new places.',
  }),
  CatFact({
    'fi': 'Kissat voivat tarkistaa huoneen ennen kuin rentoutuvat.',
    'en': 'Cats may inspect a room before relaxing.',
  }),
  CatFact({
    'fi': 'Kissat voivat muistaa suosikkipaikkansa.',
    'en': 'Cats can remember their favorite places.',
  }),
  CatFact({
    'fi': 'Kissat voivat palata samaan nukkumapaikkaan usein.',
    'en': 'Cats may return to the same sleeping place often.',
  }),
  CatFact({
    'fi': 'Kissat voivat vaihtaa suosikkipaikkaansa ajan myötä.',
    'en': 'Cats can change their favorite place over time.',
  }),
  CatFact({
    'fi': 'Kissat voivat nauttia rauhallisesta musiikista.',
    'en': 'Cats may enjoy calm music.',
  }),
  CatFact({
    'fi': 'Kissat voivat reagoida erilaisiin ääniin eri tavoin.',
    'en': 'Cats can react differently to different sounds.',
  }),
  CatFact({
    'fi': 'Kissat voivat tunnistaa tutun auton äänen.',
    'en': 'Cats may recognize the sound of a familiar car.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia, milloin joku on tulossa kotiin.',
    'en': 'Cats can learn when someone is likely to come home.',
  }),
  CatFact({
    'fi': 'Kissat voivat odottaa ovella tuttua ihmistä.',
    'en': 'Cats may wait by the door for a familiar person.',
  }),
  CatFact({
    'fi': 'Kissat voivat osoittaa kiintymystä monilla tavoilla.',
    'en': 'Cats can show affection in many ways.',
  }),
  CatFact({
    'fi': 'Pään puskeminen voi olla kissan tapa osoittaa kiintymystä.',
    'en': 'Head bunting can be a cat’s way of showing affection.',
  }),
  CatFact({
    'fi': 'Kissan vieressä istuminen voi olla merkki luottamuksesta.',
    'en': 'Sitting near someone can be a sign of trust.',
  }),
  CatFact({
    'fi': 'Kissat voivat seurata suosikki-ihmistään ympäri kotia.',
    'en': 'Cats may follow their favorite person around the home.',
  }),
  CatFact({
    'fi': 'Kissat voivat nukkua ihmisen lähellä tunteakseen olonsa turvalliseksi.',
    'en': 'Cats may sleep near people to feel safe.',
  }),
  CatFact({
    'fi': 'Kissat voivat nauttia hellästä rapsuttamisesta.',
    'en': 'Cats may enjoy gentle petting.',
  }),
  CatFact({
    'fi': 'Monet kissat pitävät rapsutuksesta poskien alueella.',
    'en': 'Many cats enjoy scratches around the cheeks.',
  }),
  CatFact({
    'fi': 'Jokaisella kissalla on omat mieluisat kosketusalueensa.',
    'en': 'Every cat has its own preferred areas for touch.',
  }),
  CatFact({
    'fi': 'Kissat voivat näyttää, milloin ne haluavat olla rauhassa.',
    'en': 'Cats can show when they want to be left alone.',
  }),
  CatFact({
    'fi': 'Kissan rajojen kunnioittaminen voi lisätä luottamusta.',
    'en': 'Respecting a cat’s boundaries can increase trust.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää häntäänsä tasapainon lisäksi viestintään.',
    'en': 'Cats use their tails for communication as well as balance.',
  }),
  CatFact({
    'fi': 'Hitaasti liikkuva häntä voi kertoa keskittymisestä.',
    'en': 'A slowly moving tail can indicate concentration.',
  }),
  CatFact({
    'fi': 'Nopeasti heiluvat hännän liikkeet voivat kertoa ärsyyntymisestä.',
    'en': 'Rapid tail movements can indicate irritation.',
  }),
  CatFact({
    'fi': 'Kissan korvat voivat kertoa paljon sen tunnetilasta.',
    'en': 'A cat’s ears can reveal a lot about its emotional state.',
  }),
  CatFact({
    'fi': 'Eteenpäin suunnatut korvat voivat kertoa kiinnostuksesta.',
    'en': 'Forward-facing ears can indicate interest.',
  }),
  CatFact({
    'fi': 'Taaksepäin painuneet korvat voivat olla varoitusmerkki.',
    'en': 'Flattened ears can be a warning sign.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää koko vartaloaan viestintään.',
    'en': 'Cats can use their whole bodies for communication.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin ilmeikkäitä ilman ääntä.',
    'en': 'Cats can be very expressive without making sounds.',
  }),
  CatFact({
    'fi': 'Kissan silmien koko voi muuttua valaistuksen mukaan.',
    'en': 'The size of a cat’s pupils changes with lighting.',
  }),
  CatFact({
    'fi': 'Kissan pupillit voivat muuttua myös tunnetilan vuoksi.',
    'en': 'A cat’s pupils can also change with emotional state.',
  }),
  CatFact({
    'fi': 'Kissat voivat tarkkailla ympäristöään lähes liikkumatta.',
    'en': 'Cats can observe their surroundings while remaining almost still.',
  }),
  CatFact({
    'fi': 'Kissat säästävät energiaa lepäämällä paljon.',
    'en': 'Cats conserve energy by resting a lot.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla aktiivisia lyhyissä jaksoissa.',
    'en': 'Cats can be active in short bursts.',
  }),
  CatFact({
    'fi': 'Nopea spurtti voi olla osa kissan leikkiä.',
    'en': 'A quick sprint can be part of a cat’s play.',
  }),
  CatFact({
    'fi': 'Kissat voivat juosta yhtäkkiä ympäri kotia.',
    'en': 'Cats may suddenly run around the home.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää leikkiä energian purkamiseen.',
    'en': 'Cats can use play to release energy.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla erittäin nopeita suunnanvaihdoksissa.',
    'en': 'Cats can change direction very quickly.',
  }),
  CatFact({
    'fi': 'Kissan joustava selkäranka auttaa ketterissä liikkeissä.',
    'en': 'A cat’s flexible spine helps with agile movement.',
  }),
  CatFact({
    'fi': 'Kissat voivat pujotella pienistä aukoista.',
    'en': 'Cats can squeeze through surprisingly small openings.',
  }),
  CatFact({
    'fi': 'Kissan viikset voivat auttaa arvioimaan, mahtuuko se aukosta.',
    'en': 'A cat’s whiskers can help estimate whether it fits through an opening.',
  }),
  CatFact({
    'fi': 'Kissat ovat tunnettuja ketteryydestään.',
    'en': 'Cats are known for their agility.',
  }),
  CatFact({
    'fi': 'Kissat voivat kiivetä monenlaisille pinnoille.',
    'en': 'Cats can climb many different surfaces.',
  }),

  // 251–300

  CatFact({
    'fi': 'Kissat voivat pitää korkeista tähystyspaikoista.',
    'en': 'Cats may enjoy high observation points.',
  }),
  CatFact({
    'fi': 'Korkea paikka voi antaa kissalle hyvän näkymän ympäristöön.',
    'en': 'A high place can give a cat a good view of its surroundings.',
  }),
  CatFact({
    'fi': 'Kissat voivat tuntea olonsa turvalliseksi omalla alueellaan.',
    'en': 'Cats can feel secure in their own territory.',
  }),
  CatFact({
    'fi': 'Kissat voivat merkitä aluettaan tuoksujen avulla.',
    'en': 'Cats can mark territory through scent.',
  }),
  CatFact({
    'fi': 'Kissat voivat jättää tuoksuaan hieromalla esineitä.',
    'en': 'Cats can leave their scent by rubbing against objects.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää raapimista alueen merkintään.',
    'en': 'Cats can use scratching to mark territory.',
  }),
  CatFact({
    'fi': 'Kissat voivat tuntea olonsa turvallisemmaksi tuttujen hajujen keskellä.',
    'en': 'Cats may feel safer around familiar scents.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla herkkiä uusille hajuille.',
    'en': 'Cats can be sensitive to new smells.',
  }),
  CatFact({
    'fi': 'Kissat voivat tutkia vierasta ihmistä ensin haistamalla.',
    'en': 'Cats may investigate a stranger first by smelling.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät paljon aikaa turkkinsa hoitamiseen.',
    'en': 'Cats spend a lot of time grooming their fur.',
  }),
  CatFact({
    'fi': 'Turkin hoitaminen voi auttaa poistamaan likaa.',
    'en': 'Grooming can help remove dirt.',
  }),
  CatFact({
    'fi': 'Kissat voivat hoitaa itseään erityisen paljon levon jälkeen.',
    'en': 'Cats may groom themselves a lot after resting.',
  }),
  CatFact({
    'fi': 'Kissat voivat nuolla tassuaan ja käyttää sitä kasvojen pesuun.',
    'en': 'Cats may lick a paw and use it to clean their face.',
  }),
  CatFact({
    'fi': 'Kissan kieli on tärkeä työkalu turkinhoidossa.',
    'en': 'A cat’s tongue is an important grooming tool.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin tarkkoja puhtaudestaan.',
    'en': 'Cats can be very particular about cleanliness.',
  }),
  CatFact({
    'fi': 'Kissat voivat välttää likaista paikkaa.',
    'en': 'Cats may avoid a dirty place.',
  }),
  CatFact({
    'fi': 'Kissat voivat pitää puhtaasta juomavedestä.',
    'en': 'Cats may prefer clean drinking water.',
  }),
  CatFact({
    'fi': 'Jotkut kissat pitävät juoksevasta vedestä.',
    'en': 'Some cats enjoy running water.',
  }),
  CatFact({
    'fi': 'Kissat voivat kiinnostua hanasta tulevasta vedestä.',
    'en': 'Cats may be interested in water coming from a tap.',
  }),
  CatFact({
    'fi': 'Veden saanti on tärkeä osa kissan hyvinvointia.',
    'en': 'Access to water is an important part of a cat’s well-being.',
  }),
  CatFact({
    'fi': 'Kissat voivat syödä pieniä aterioita päivän aikana.',
    'en': 'Cats may eat small meals throughout the day.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia ruokailuajat.',
    'en': 'Cats can learn regular meal times.',
  }),
  CatFact({
    'fi': 'Ruokarutiini voi auttaa tekemään päivästä ennakoitavan.',
    'en': 'A feeding routine can make the day more predictable.',
  }),
  CatFact({
    'fi': 'Kissat voivat ilmaista ruokahaluaan maukumalla.',
    'en': 'Cats may express hunger by meowing.',
  }),
  CatFact({
    'fi': 'Kissat voivat odottaa ruokaansa kärsivällisesti.',
    'en': 'Cats can wait patiently for food.',
  }),
  CatFact({
    'fi': 'Toiset kissat ovat ruokailun suhteen kärsimättömämpiä.',
    'en': 'Other cats can be less patient about meals.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla nirsoja ruoan suhteen.',
    'en': 'Cats can be picky about food.',
  }),
  CatFact({
    'fi': 'Kissan makumieltymykset voivat vaihdella.',
    'en': 'A cat’s food preferences can vary.',
  }),
  CatFact({
    'fi': 'Kissat voivat tutkia uutta ruokaa ensin haistamalla.',
    'en': 'Cats may investigate new food by smelling it first.',
  }),
  CatFact({
    'fi': 'Kissat voivat nauttia rauhallisesta ruokailupaikasta.',
    'en': 'Cats may enjoy eating in a quiet place.',
  }),
  CatFact({
    'fi': 'Kissat voivat pitää omasta ruokapaikastaan.',
    'en': 'Cats may prefer having their own eating area.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla tarkkoja ruokakupin puhtaudesta.',
    'en': 'Cats can be particular about a clean food bowl.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää tassuaan ruoan tutkimiseen.',
    'en': 'Cats may use a paw to investigate food.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia monia asioita tarkkailemalla.',
    'en': 'Cats can learn many things by observing.',
  }),
  CatFact({
    'fi': 'Kissat voivat seurata ihmisen toimintaa tarkasti.',
    'en': 'Cats can closely watch human activity.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia, missä tavaroita säilytetään.',
    'en': 'Cats can learn where things are stored.',
  }),
  CatFact({
    'fi': 'Kissat voivat muistaa reittejä kotonaan.',
    'en': 'Cats can remember routes around their home.',
  }),
  CatFact({
    'fi': 'Kissat voivat löytää suosikkipiilopaikkansa nopeasti.',
    'en': 'Cats can quickly find their favorite hiding place.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää piilopaikkoja levätäkseen.',
    'en': 'Cats may use hiding places to rest.',
  }),
  CatFact({
    'fi': 'Turvallinen piilopaikka voi auttaa kissaa rentoutumaan.',
    'en': 'A safe hiding place can help a cat relax.',
  }),
  CatFact({
    'fi': 'Kissat voivat tulla ulos piilosta, kun ne tuntevat olonsa turvalliseksi.',
    'en': 'Cats may come out of hiding when they feel safe.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla rohkeampia tutussa ympäristössä.',
    'en': 'Cats can be braver in familiar surroundings.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla varovaisempia uudessa paikassa.',
    'en': 'Cats can be more cautious in a new place.',
  }),
  CatFact({
    'fi': 'Uuteen kotiin tottuminen voi viedä aikaa.',
    'en': 'Adjusting to a new home can take time.',
  }),
  CatFact({
    'fi': 'Kissat voivat tutkia uutta ympäristöä vähitellen.',
    'en': 'Cats may explore a new environment gradually.',
  }),
  CatFact({
    'fi': 'Rauhallinen ympäristö voi helpottaa sopeutumista.',
    'en': 'A calm environment can make adjustment easier.',
  }),
  CatFact({
    'fi': 'Kissat voivat muodostaa vahvan suhteen tuttuun kotiin.',
    'en': 'Cats can form a strong connection with a familiar home.',
  }),
  CatFact({
    'fi': 'Kissat voivat tunnistaa oman alueensa hajujen avulla.',
    'en': 'Cats can recognize their territory through scent.',
  }),
  CatFact({
    'fi': 'Kissat voivat palata mielellään omiin suosikkipaikkoihinsa.',
    'en': 'Cats often like returning to their favorite places.',
  }),
  CatFact({
    'fi': 'Kissat voivat tehdä samasta paikasta päivittäisen lepopaikan.',
    'en': 'Cats may turn the same place into a daily resting spot.',
  }),

  // 301–365

  CatFact({
    'fi': 'Kissat voivat olla aktiivisia heti pitkän unen jälkeen.',
    'en': 'Cats can become active immediately after a long sleep.',
  }),
  CatFact({
    'fi': 'Venytteleminen valmistaa kissaa liikkumiseen.',
    'en': 'Stretching helps prepare a cat for movement.',
  }),
  CatFact({
    'fi': 'Kissat voivat venyttää etu- ja takajalkojaan erikseen.',
    'en': 'Cats can stretch their front and back legs separately.',
  }),
  CatFact({
    'fi': 'Kissat voivat haukotella aivan kuten ihmiset.',
    'en': 'Cats can yawn just like humans.',
  }),
  CatFact({
    'fi': 'Kissat voivat näyttää hyvin rentoutuneilta nukkuessaan.',
    'en': 'Cats can look very relaxed while sleeping.',
  }),
  CatFact({
    'fi': 'Kissat voivat nähdä unia unen aikana.',
    'en': 'Cats can dream while sleeping.',
  }),
  CatFact({
    'fi': 'Nukkuvan kissan tassut voivat joskus nykiä.',
    'en': 'A sleeping cat’s paws may sometimes twitch.',
  }),
  CatFact({
    'fi': 'Kissan korvat voivat liikkua, vaikka se lepää.',
    'en': 'A cat’s ears may move even while resting.',
  }),
  CatFact({
    'fi': 'Kissat voivat herätä nopeasti mielenkiintoiseen ääneen.',
    'en': 'Cats can wake quickly to an interesting sound.',
  }),
  CatFact({
    'fi': 'Kissat voivat levätä kevyesti ja pysyä samalla tarkkaavaisina.',
    'en': 'Cats can rest lightly while remaining alert.',
  }),
  CatFact({
    'fi': 'Kissat ovat taitavia säästämään energiaa.',
    'en': 'Cats are skilled at conserving energy.',
  }),
  CatFact({
    'fi': 'Lyhyet aktiiviset hetket ovat kissalle luonnollisia.',
    'en': 'Short active periods are natural for cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat leikkiä yksin tai ihmisen kanssa.',
    'en': 'Cats can play alone or with people.',
  }),
  CatFact({
    'fi': 'Yhteinen leikki voi olla hauskaa sekä kissalle että ihmiselle.',
    'en': 'Shared play can be fun for both cats and people.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin luovia leikkiessään.',
    'en': 'Cats can be very creative while playing.',
  }),
  CatFact({
    'fi': 'Paperipussi voi kiinnostaa kissaa enemmän kuin kallis lelu.',
    'en': 'A paper bag may interest a cat more than an expensive toy.',
  }),
  CatFact({
    'fi': 'Laatikot ovat monien kissojen suosikkeja.',
    'en': 'Boxes are favorites of many cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat istua yllättävän pienissä laatikoissa.',
    'en': 'Cats can sit in surprisingly small boxes.',
  }),
  CatFact({
    'fi': 'Kissat voivat tutkia laatikkoa ennen kuin menevät sen sisään.',
    'en': 'Cats may inspect a box before climbing inside.',
  }),
  CatFact({
    'fi': 'Laatikko voi tarjota kissalle turvallisen tunteen.',
    'en': 'A box can give a cat a sense of security.',
  }),
  CatFact({
    'fi': 'Kissat voivat tehdä melkein mistä tahansa paikasta lepopaikan.',
    'en': 'Cats can turn almost any place into a resting spot.',
  }),
  CatFact({
    'fi': 'Kissat voivat vaihtaa suosikkipaikkaansa sään mukaan.',
    'en': 'Cats can change favorite places depending on the weather.',
  }),
  CatFact({
    'fi': 'Talvella lämmin paikka voi olla erityisen houkutteleva.',
    'en': 'A warm place can be especially attractive in winter.',
  }),
  CatFact({
    'fi': 'Kesällä viileä lattia voi tuntua kissasta mukavalta.',
    'en': 'A cool floor can feel comfortable to a cat in summer.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia kodin lämpimimmät paikat.',
    'en': 'Cats can learn where the warmest places in a home are.',
  }),
  CatFact({
    'fi': 'Kissat voivat löytää auringonsäteen nopeasti.',
    'en': 'Cats can quickly find a patch of sunlight.',
  }),
  CatFact({
    'fi': 'Kissat voivat seurata auringon liikettä päivän aikana.',
    'en': 'Cats may follow the movement of sunlight during the day.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin kärsivällisiä saadakseen haluamansa paikan.',
    'en': 'Cats can be very patient when waiting for a desired spot.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin päättäväisiä.',
    'en': 'Cats can be very determined.',
  }),
  CatFact({
    'fi': 'Kissat voivat yrittää uudelleen, jos ensimmäinen yritys epäonnistuu.',
    'en': 'Cats may try again if their first attempt fails.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia kokemuksistaan.',
    'en': 'Cats can learn from experience.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla taitavia ratkaisemaan yksinkertaisia ongelmia.',
    'en': 'Cats can be skilled at solving simple problems.',
  }),
  CatFact({
    'fi': 'Kissat voivat muistaa, miten saavuttaa suosikkipaikkansa.',
    'en': 'Cats can remember how to reach a favorite place.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia tarkkailemalla muita.',
    'en': 'Cats can learn by watching others.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla erittäin tarkkoja ympäristöstään.',
    'en': 'Cats can be highly attentive to their environment.',
  }),
  CatFact({
    'fi': 'Kissat voivat havaita pieniä muutoksia kotonaan.',
    'en': 'Cats can notice small changes in their home.',
  }),
  CatFact({
    'fi': 'Uusi huonekalu voi herättää kissan uteliaisuuden.',
    'en': 'New furniture can spark a cat’s curiosity.',
  }),
  CatFact({
    'fi': 'Kissat voivat tutkia uusia asioita vähitellen.',
    'en': 'Cats may investigate new things gradually.',
  }),
  CatFact({
    'fi': 'Kissat voivat palata myöhemmin tutkimaan jotain uudelleen.',
    'en': 'Cats may return later to investigate something again.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla hyvin hyviä löytämään piilotettuja paikkoja.',
    'en': 'Cats can be very good at finding hidden places.',
  }),
  CatFact({
    'fi': 'Kissat voivat tehdä kodista oman valtakuntansa.',
    'en': 'Cats can turn a home into their own kingdom.',
  }),
  CatFact({
    'fi': 'Jokainen kissa on yksilö omine tapoineen.',
    'en': 'Every cat is an individual with its own habits.',
  }),
  CatFact({
    'fi': 'Kissan persoonallisuus voi muuttua sen kasvaessa.',
    'en': 'A cat’s personality can change as it grows.',
  }),
  CatFact({
    'fi': 'Luottamus rakentuu kissan kanssa usein vähitellen.',
    'en': 'Trust with a cat is often built gradually.',
  }),
  CatFact({
    'fi': 'Rauhallinen ja turvallinen suhde voi kestää vuosia.',
    'en': 'A calm and safe relationship can last for years.',
  }),
  CatFact({
    'fi': 'Kissat voivat tuoda paljon iloa ihmisten elämään.',
    'en': 'Cats can bring a lot of joy into people’s lives.',
  }),
  CatFact({
    'fi': 'Kissat voivat olla uskollisia omalla ainutlaatuisella tavallaan.',
    'en': 'Cats can be loyal in their own unique way.',
  }),
  CatFact({
    'fi': 'Kissan seura voi olla rauhoittavaa.',
    'en': 'The company of a cat can be calming.',
  }),
  CatFact({
    'fi': 'Kissat voivat tehdä tavallisesta päivästä hauskemman.',
    'en': 'Cats can make an ordinary day more fun.',
  }),
  CatFact({
    'fi': 'Jokainen päivä voi olla uusi seikkailu uteliaalle kissalle.',
    'en': 'Every day can be a new adventure for a curious cat.',
  }),
  CatFact({
    'fi': 'Kissat muistuttavat meitä pysähtymään ja lepäämään.',
    'en': 'Cats remind us to slow down and rest.',
  }),
  CatFact({
    'fi': 'Kissan uteliaisuus voi johtaa hauskoihin tilanteisiin.',
    'en': 'A cat’s curiosity can lead to funny situations.',
  }),
  CatFact({
    'fi': 'Kissat ovat pieniä, mutta niiden persoonallisuus voi olla valtava.',
    'en': 'Cats may be small, but their personalities can be huge.',
  }),
  CatFact({
    'fi': 'Kissa voi tehdä kodista kodikkaamman pelkällä läsnäolollaan.',
    'en': 'A cat can make a home feel cozier simply by being there.',
  }),
  CatFact({
    'fi': 'Jokainen päivä kissan kanssa voi tarjota jotain uutta.',
    'en': 'Every day with a cat can offer something new.',
  }),
  CatFact({
    'fi': 'Kissat ovat mestareita löytämään mukavan paikan.',
    'en': 'Cats are masters at finding comfortable places.',
  }),
  CatFact({
    'fi': 'Kissat osaavat usein näyttää, milloin on aika levätä.',
    'en': 'Cats often know how to show when it is time to rest.',
  }),
  CatFact({
    'fi': 'Kissan elämässä uteliaisuus ja lepo kulkevat usein yhdessä.',
    'en': 'In a cat’s life, curiosity and rest often go together.',
  }),
  CatFact({
    'fi': 'Vuoden viimeinen kissafakta: kissat ovat yksinkertaisesti mahtavia! 🐱',
    'en': 'The final cat fact of the year: cats are simply amazing! 🐱',
  }),
];