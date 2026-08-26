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
    'fi': 'Kissat nukkuvat usein noin 12–16 tuntia vuorokaudessa.',
    'en': 'Cats often sleep around 12–16 hours a day.',
    'sv': 'Katter sover ofta omkring 12–16 timmar om dagen.',
    'de': 'Katzen schlafen oft etwa 12–16 Stunden am Tag.',
    'es': 'Los gatos suelen dormir unas 12–16 horas al día.',
    'fr': 'Les chats dorment souvent environ 12 à 16 heures par jour.',
    'it': 'I gatti dormono spesso circa 12–16 ore al giorno.',
    'pt': 'Os gatos costumam dormir cerca de 12–16 horas por dia.',
    'ja': '猫は1日に約12〜16時間眠ることがよくあります。',
    'zh': '猫咪每天通常会睡大约12到16个小时。',
  }),

  CatFact({
    'fi': 'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'en': 'A cat’s whiskers are very sensitive sensory organs.',
    'sv': 'Kattens morrhår är mycket känsliga sinnesorgan.',
    'de': 'Die Schnurrhaare einer Katze sind sehr empfindliche Sinnesorgane.',
    'es': 'Los bigotes de los gatos son órganos sensoriales muy sensibles.',
    'fr': 'Les moustaches des chats sont des organes sensoriels très sensibles.',
    'it': 'I baffi dei gatti sono organi sensoriali molto sensibili.',
    'pt': 'Os bigodes dos gatos são órgãos sensoriais muito sensíveis.',
    'ja': '猫のひげは非常に敏感な感覚器官です。',
    'zh': '猫咪的胡须是非常敏感的感觉器官。',
  }),

  CatFact({
    'fi': 'Kissan nenän kuvio on yksilöllinen.',
    'en': 'Every cat has a unique nose pattern.',
    'sv': 'Varje katt har ett unikt nosmönster.',
    'de': 'Jede Katze hat ein einzigartiges Nasenmuster.',
    'es': 'Cada gato tiene un patrón nasal único.',
    'fr': 'Chaque chat possède un motif nasal unique.',
    'it': 'Ogni gatto ha un motivo nasale unico.',
    'pt': 'Cada gato tem um padrão nasal único.',
    'ja': '猫の鼻の模様は一匹ずつ異なります。',
    'zh': '每只猫咪的鼻纹都是独一无二的。',
  }),

  CatFact({
    'fi': 'Kissat voivat kuulla erittäin korkeita ääniä.',
    'en': 'Cats can hear very high-frequency sounds.',
    'sv': 'Katter kan höra mycket högfrekventa ljud.',
    'de': 'Katzen können sehr hochfrequente Geräusche hören.',
    'es': 'Los gatos pueden oír sonidos de frecuencias muy altas.',
    'fr': 'Les chats peuvent entendre des sons de très haute fréquence.',
    'it': 'I gatti possono sentire suoni a frequenze molto alte.',
    'pt': 'Os gatos conseguem ouvir sons de frequências muito altas.',
    'ja': '猫は非常に高い周波数の音を聞くことができます。',
    'zh': '猫咪可以听到频率非常高的声音。',
  }),

  CatFact({
    'fi': 'Kissan kynnet ovat sisäänvedettävät.',
    'en': 'Cats have retractable claws.',
    'sv': 'Katter har infällbara klor.',
    'de': 'Katzen haben einziehbare Krallen.',
    'es': 'Los gatos tienen garras retráctiles.',
    'fr': 'Les chats ont des griffes rétractiles.',
    'it': 'I gatti hanno artigli retrattili.',
    'pt': 'Os gatos têm garras retráteis.',
    'ja': '猫の爪は出し入れすることができます。',
    'zh': '猫咪的爪子可以伸缩。',
  }),

  CatFact({
    'fi': 'Kissat käyttävät häntäänsä myös tasapainon apuna.',
    'en': 'Cats also use their tails to help with balance.',
    'sv': 'Katter använder också svansen för att hålla balansen.',
    'de': 'Katzen benutzen ihren Schwanz auch zum Balancieren.',
    'es': 'Los gatos también usan la cola para mantener el equilibrio.',
    'fr': 'Les chats utilisent aussi leur queue pour garder leur équilibre.',
    'it': 'I gatti usano anche la coda per mantenere l’equilibrio.',
    'pt': 'Os gatos também usam a cauda para ajudar no equilíbrio.',
    'ja': '猫は尻尾を使ってバランスを取ります。',
    'zh': '猫咪也会利用尾巴帮助保持平衡。',
  }),

  CatFact({
    'fi': 'Hidas silmien räpytys voi olla kissan ystävällinen tervehdys.',
    'en': 'A slow blink can be a friendly greeting from a cat.',
    'sv': 'En långsam blinkning kan vara en vänlig hälsning från en katt.',
    'de': 'Langsames Blinzeln kann bei Katzen ein freundlicher Gruß sein.',
    'es': 'Un parpadeo lento puede ser un saludo amistoso de un gato.',
    'fr': 'Un clignement lent peut être un salut amical d’un chat.',
    'it': 'Un lento battito delle palpebre può essere un saluto amichevole.',
    'pt': 'Um piscar lento pode ser uma saudação amigável de um gato.',
    'ja': 'ゆっくりしたまばたきは猫からの友好的な挨拶かもしれません。',
    'zh': '猫咪缓慢眨眼可能是一种友好的问候。',
  }),

  CatFact({
    'fi': 'Kissat pitävät usein korkeista tarkkailupaikoista.',
    'en': 'Cats often enjoy high places where they can observe their surroundings.',
    'sv': 'Katter tycker ofta om höga platser där de kan observera omgivningen.',
    'de': 'Katzen mögen oft hohe Plätze, von denen sie ihre Umgebung beobachten können.',
    'es': 'A los gatos suelen gustarles los lugares altos para observar su entorno.',
    'fr': 'Les chats aiment souvent les endroits élevés pour observer leur environnement.',
    'it': 'I gatti spesso amano i luoghi elevati da cui osservare l’ambiente.',
    'pt': 'Os gatos costumam gostar de lugares altos para observar o ambiente.',
    'ja': '猫は周囲を見渡せる高い場所を好むことがあります。',
    'zh': '猫咪通常喜欢待在可以观察周围环境的高处。',
  }),

  CatFact({
    'fi': 'Kissan kielessä on pieniä koukkumaisia nystyjä.',
    'en': 'A cat’s tongue has tiny hook-like structures.',
    'sv': 'Kattens tunga har små krokformade strukturer.',
    'de': 'Die Zunge einer Katze hat kleine hakenförmige Strukturen.',
    'es': 'La lengua de un gato tiene pequeñas estructuras en forma de gancho.',
    'fr': 'La langue du chat possède de petites structures en forme de crochets.',
    'it': 'La lingua del gatto presenta piccole strutture simili a uncini.',
    'pt': 'A língua do gato possui pequenas estruturas semelhantes a ganchos.',
    'ja': '猫の舌には小さな鉤状の突起があります。',
    'zh': '猫咪的舌头上有许多细小的钩状突起。',
  }),

  CatFact({
    'fi': 'Kissat voivat käyttää kehräystä viestintään.',
    'en': 'Cats can use purring as a form of communication.',
    'sv': 'Katter kan använda spinnande som kommunikation.',
    'de': 'Katzen können Schnurren zur Kommunikation verwenden.',
    'es': 'Los gatos pueden usar el ronroneo para comunicarse.',
    'fr': 'Les chats peuvent utiliser le ronronnement pour communiquer.',
    'it': 'I gatti possono usare le fusa per comunicare.',
    'pt': 'Os gatos podem usar o ronronar como forma de comunicação.',
    'ja': '猫はゴロゴロと喉を鳴らしてコミュニケーションすることがあります。',
    'zh': '猫咪可以通过呼噜声进行交流。',
  }),

  CatFact({
    'fi': 'Kissat käyttävät paljon aikaa turkkinsa hoitamiseen.',
    'en': 'Cats spend a lot of time grooming their fur.',
    'sv': 'Katter ägnar mycket tid åt att sköta sin päls.',
    'de': 'Katzen verbringen viel Zeit mit der Fellpflege.',
    'es': 'Los gatos pasan mucho tiempo limpiando su pelaje.',
    'fr': 'Les chats passent beaucoup de temps à entretenir leur pelage.',
    'it': 'I gatti trascorrono molto tempo a pulire il loro pelo.',
    'pt': 'Os gatos passam bastante tempo cuidando do próprio pelo.',
    'ja': '猫は毛づくろいに多くの時間を使います。',
    'zh': '猫咪会花很多时间梳理自己的毛发。',
  }),

  CatFact({
    'fi': 'Kissat ovat luonnostaan uteliaita eläimiä.',
    'en': 'Cats are naturally curious animals.',
    'sv': 'Katter är naturligt nyfikna djur.',
    'de': 'Katzen sind von Natur aus neugierige Tiere.',
    'es': 'Los gatos son animales naturalmente curiosos.',
    'fr': 'Les chats sont naturellement curieux.',
    'it': 'I gatti sono animali naturalmente curiosi.',
    'pt': 'Os gatos são animais naturalmente curiosos.',
    'ja': '猫はもともと好奇心の強い動物です。',
    'zh': '猫咪天生就是充满好奇心的动物。',
  }),

  CatFact({
    'fi': 'Kissat voivat hypätä erittäin ketterästi.',
    'en': 'Cats can jump with remarkable agility.',
    'sv': 'Katter kan hoppa med stor smidighet.',
    'de': 'Katzen können bemerkenswert geschickt springen.',
    'es': 'Los gatos pueden saltar con gran agilidad.',
    'fr': 'Les chats peuvent sauter avec une grande agilité.',
    'it': 'I gatti possono saltare con grande agilità.',
    'pt': 'Os gatos conseguem saltar com grande agilidade.',
    'ja': '猫はとても機敏にジャンプできます。',
    'zh': '猫咪可以非常灵活地跳跃。',
  }),

  CatFact({
    'fi': 'Kissat voivat muodostaa vahvan siteen ihmiseen.',
    'en': 'Cats can form strong bonds with people.',
    'sv': 'Katter kan skapa starka band till människor.',
    'de': 'Katzen können starke Bindungen zu Menschen aufbauen.',
    'es': 'Los gatos pueden crear fuertes vínculos con las personas.',
    'fr': 'Les chats peuvent créer des liens forts avec les humains.',
    'it': 'I gatti possono creare forti legami con le persone.',
    'pt': 'Os gatos podem criar laços fortes com as pessoas.',
    'ja': '猫は人と強い絆を築くことがあります。',
    'zh': '猫咪可以与人类建立深厚的感情。',
  }),

  CatFact({
    'fi': 'Jokaisella kissalla voi olla oma persoonallisuutensa.',
    'en': 'Every cat can have its own unique personality.',
    'sv': 'Varje katt kan ha sin egen unika personlighet.',
    'de': 'Jede Katze kann ihre eigene Persönlichkeit haben.',
    'es': 'Cada gato puede tener su propia personalidad.',
    'fr': 'Chaque chat peut avoir sa propre personnalité.',
    'it': 'Ogni gatto può avere una personalità unica.',
    'pt': 'Cada gato pode ter a sua própria personalidade.',
    'ja': '猫にはそれぞれ個性的な性格があります。',
    'zh': '每只猫咪都可能拥有独特的性格。',
  }),
];