// ============================================================
// 🐱 STELLURIINI / STELLA DAILY CAT FACTS
//
// Päivämäärä määrittää automaattisesti päivän faktan.
// Sama päivä näyttää saman faktan kaikille käyttäjille.
// Kieli määräytyy sovelluksen nykyisen kielikoodin mukaan.
// ============================================================

class CatFacts {
  // ==========================================================
  // 🐱 SUOMI
  // ==========================================================

  static const List<String> fi = [
    'Kissat nukkuvat yleensä noin 12–16 tuntia vuorokaudessa.',
    'Kissat voivat hypätä noin viisi kertaa oman pituutensa korkeudelle.',
    'Kissan viikset auttavat sitä arvioimaan ympäröivää tilaa.',
    'Kissat käyttävät häntäänsä tasapainon säilyttämiseen.',
    'Kissan nenän yksilöllinen kuvio on ainutlaatuinen.',
    'Kissat pystyvät kuulemaan paljon korkeampia ääniä kuin ihmiset.',
    'Kissan kehräys voi esiintyä myös silloin, kun kissa on stressaantunut.',
    'Kissat käyttävät korviaan ilmaistakseen mielialojaan.',
    'Kissan etutassuissa on yleensä viisi varvasta ja takatassuissa neljä.',
    'Kissat käyttävät hajuaistiaan ympäristönsä tutkimiseen.',
    'Kissat voivat oppia tunnistamaan oman nimensä.',
    'Kissan silmien pupillit voivat muuttua nopeasti valon määrän mukaan.',
    'Kissat viettävät suuren osan hereilläoloajastaan turkkinsa hoitamiseen.',
    'Kissan kielessä on pieniä koukkumaisia papilleja, jotka auttavat turkin hoidossa.',
    'Kissat kommunikoivat keskenään paljon hajujen ja kehonkielen avulla.',
    'Kissa voi käyttää kehräystä rauhoittaakseen itseään.',
    'Kissoilla on erittäin herkkä tasapainoaisti.',
    'Kissat voivat tunnistaa tuttuja ihmisiä äänen perusteella.',
    'Kissan viikset sijaitsevat myös silmien yläpuolella ja leuan alueella.',
    'Kissat ovat luonnostaan uteliaita ja tutkivat mielellään uusia paikkoja.',
    'Kissan sydän lyö normaalisti nopeammin kuin ihmisen sydän.',
    'Kissat voivat käyttää kehon asentoa viestittääkseen toisille kissoille.',
    'Kissat voivat nähdä hämärässä paremmin kuin ihmiset.',
    'Kissan kynnet voivat vetäytyä osittain tassun sisään.',
    'Kissat voivat tehdä hyvin nopeita suunnanmuutoksia juostessaan.',
    'Kissan hajuaisti on huomattavasti ihmisen hajuaistia herkempi.',
    'Kissat voivat oppia erilaisia rutiineja seuraamalla ympäristöään.',
    'Kissa voi heiluttaa häntäänsä eri tavoin ilmaistakseen erilaisia tunnetiloja.',
    'Kissoilla on hyvä muisti erityisesti tutuissa ympäristöissä.',
    'Kissan tassuissa on herkkiä tuntohermoja, jotka auttavat ympäristön tutkimisessa.',
    'Kissat venyttelevät usein levon jälkeen valmistautuakseen liikkumaan.',
    'Kissan silmien heijastava kerros auttaa sitä hyödyntämään vähäistä valoa.',
    'Kissat voivat kommunikoida ihmisten kanssa erilaisilla naukumisen äänillä.',
    'Kissa käyttää viiksiään myös saaliin ja ympäristön läheisyyden arvioimiseen.',
    'Kissat voivat oppia avaamaan yksinkertaisia ovia ja laatikoita.',
    'Kissan korvat voivat liikkua toisistaan riippumatta.',
    'Kissat voivat käyttää korkeita paikkoja ympäristön tarkkailuun.',
    'Kissan kehon kieli kertoo usein enemmän kuin pelkkä ääntely.',
    'Kissat ovat erittäin taitavia säilyttämään tasapainonsa kapeilla pinnoilla.',
    'Kissat voivat nukkua useita lyhyitä jaksoja yhden pitkän unen sijaan.',
  ];

  // ==========================================================
  // 🇬🇧 ENGLISH
  // ==========================================================

  static const List<String> en = [
    'Cats usually sleep around 12–16 hours a day.',
    'Cats can jump about five times their own body length in height.',
    'A cat’s whiskers help it judge the space around its body.',
    'Cats use their tails to help maintain balance.',
    'Every cat has a unique pattern on its nose.',
    'Cats can hear much higher-pitched sounds than humans.',
    'Cats may purr even when they are stressed or uncomfortable.',
    'Cats use their ears to communicate their mood.',
    'Cats usually have five toes on their front paws and four on their back paws.',
    'Cats use their sense of smell to explore their surroundings.',
    'Cats can learn to recognize their own names.',
    'A cat’s pupils can change quickly depending on the amount of light.',
    'Cats spend a large part of their awake time grooming themselves.',
    'A cat’s tongue has tiny hook-like structures that help with grooming.',
    'Cats communicate with each other through scent and body language.',
    'Purring can sometimes help a cat calm itself.',
    'Cats have an excellent sense of balance.',
    'Cats can recognize familiar people by their voices.',
    'Cats have whiskers above their eyes and around their chin as well.',
    'Cats are naturally curious and enjoy exploring new places.',
    'A cat’s heart normally beats faster than a human heart.',
    'Cats can use body posture to communicate with other cats.',
    'Cats can see better in dim light than humans.',
    'A cat’s claws can retract partly into its paws.',
    'Cats can make very fast changes of direction while running.',
    'A cat’s sense of smell is much stronger than a human’s.',
    'Cats can learn routines by observing their surroundings.',
    'Cats can move their tails in different ways to express different emotions.',
    'Cats have good memory, especially in familiar environments.',
    'Sensitive nerve endings in a cat’s paws help it explore its surroundings.',
    'Cats often stretch after resting before moving around.',
    'A reflective layer in a cat’s eyes helps it use available light efficiently.',
    'Cats can communicate with humans using many different meowing sounds.',
    'A cat can use its whiskers to judge the position of nearby objects.',
    'Cats can learn to open simple doors and containers.',
    'A cat’s ears can move independently of each other.',
    'Cats often use high places to observe their surroundings.',
    'A cat’s body language can communicate more than its vocalizations.',
    'Cats are very skilled at balancing on narrow surfaces.',
    'Cats may sleep in many shorter periods instead of one long sleep.',
  ];

  // ==========================================================
  // 🇩🇪 DEUTSCH
  // ==========================================================

  static const List<String> de = [
    'Katzen schlafen normalerweise etwa 12–16 Stunden am Tag.',
    'Katzen können etwa das Fünffache ihrer eigenen Körperlänge hoch springen.',
    'Die Schnurrhaare einer Katze helfen ihr, den Raum um ihren Körper einzuschätzen.',
    'Katzen benutzen ihren Schwanz, um das Gleichgewicht zu halten.',
    'Das Nasenmuster jeder Katze ist einzigartig.',
    'Katzen können deutlich höhere Töne hören als Menschen.',
    'Katzen können auch schnurren, wenn sie gestresst sind.',
    'Katzen benutzen ihre Ohren, um ihre Stimmung auszudrücken.',
    'Katzen haben normalerweise fünf Zehen an den Vorderpfoten und vier an den Hinterpfoten.',
    'Katzen nutzen ihren Geruchssinn, um ihre Umgebung zu erkunden.',
    'Katzen können lernen, ihren eigenen Namen zu erkennen.',
    'Die Pupillen einer Katze können sich je nach Lichtmenge schnell verändern.',
    'Katzen verbringen einen großen Teil ihrer Wachzeit mit der Fellpflege.',
    'Die Zunge einer Katze besitzt kleine hakenartige Strukturen, die bei der Fellpflege helfen.',
    'Katzen kommunizieren untereinander viel über Gerüche und Körpersprache.',
    'Schnurren kann einer Katze helfen, sich selbst zu beruhigen.',
    'Katzen haben einen ausgezeichneten Gleichgewichtssinn.',
    'Katzen können vertraute Menschen an ihrer Stimme erkennen.',
    'Katzen haben Schnurrhaare auch über den Augen und im Bereich des Kinns.',
    'Katzen sind von Natur aus neugierig und erkunden gerne neue Orte.',
    'Das Herz einer Katze schlägt normalerweise schneller als das eines Menschen.',
    'Katzen können ihre Körperhaltung zur Kommunikation einsetzen.',
    'Katzen können bei schwachem Licht besser sehen als Menschen.',
    'Die Krallen einer Katze können teilweise in die Pfoten zurückgezogen werden.',
    'Katzen können beim Laufen sehr schnell die Richtung ändern.',
    'Der Geruchssinn einer Katze ist deutlich stärker als der eines Menschen.',
    'Katzen können Routinen lernen, indem sie ihre Umgebung beobachten.',
    'Katzen können mit ihrem Schwanz verschiedene Gefühle ausdrücken.',
    'Katzen haben besonders in vertrauten Umgebungen ein gutes Gedächtnis.',
    'Die empfindlichen Nerven in den Pfoten helfen Katzen, ihre Umgebung zu erkunden.',
    'Katzen strecken sich häufig nach dem Schlafen oder Ruhen.',
    'Eine reflektierende Schicht in den Augen hilft Katzen, wenig Licht besser zu nutzen.',
    'Katzen können mit Menschen durch unterschiedliche Miaugeräusche kommunizieren.',
    'Katzen können ihre Schnurrhaare nutzen, um die Nähe von Gegenständen einzuschätzen.',
    'Katzen können lernen, einfache Türen oder Behälter zu öffnen.',
    'Die Ohren einer Katze können sich unabhängig voneinander bewegen.',
    'Katzen nutzen gerne erhöhte Plätze, um ihre Umgebung zu beobachten.',
    'Die Körpersprache einer Katze kann oft mehr ausdrücken als ihre Laute.',
    'Katzen können ihr Gleichgewicht auch auf schmalen Flächen sehr gut halten.',
    'Katzen schlafen häufig in mehreren kürzeren Schlafphasen.',
  ];

  // ==========================================================
  // 🇪🇸 ESPAÑOL
  // ==========================================================

  static const List<String> es = [
    'Los gatos suelen dormir entre 12 y 16 horas al día.',
    'Los gatos pueden saltar hasta unas cinco veces la longitud de su cuerpo.',
    'Los bigotes ayudan a los gatos a calcular el espacio que los rodea.',
    'Los gatos usan la cola para mantener el equilibrio.',
    'El patrón de la nariz de cada gato es único.',
    'Los gatos pueden escuchar sonidos mucho más agudos que los humanos.',
    'Los gatos pueden ronronear incluso cuando están estresados.',
    'Los gatos utilizan las orejas para expresar su estado de ánimo.',
    'Los gatos suelen tener cinco dedos en las patas delanteras y cuatro en las traseras.',
    'Los gatos utilizan su sentido del olfato para explorar su entorno.',
    'Los gatos pueden aprender a reconocer su propio nombre.',
    'Las pupilas de un gato pueden cambiar rápidamente según la cantidad de luz.',
    'Los gatos pasan gran parte de su tiempo despiertos acicalándose.',
    'La lengua de un gato tiene pequeñas estructuras en forma de gancho que ayudan a limpiar su pelaje.',
    'Los gatos se comunican entre ellos mediante olores y lenguaje corporal.',
    'El ronroneo puede ayudar a un gato a calmarse.',
    'Los gatos tienen un excelente sentido del equilibrio.',
    'Los gatos pueden reconocer a personas conocidas por su voz.',
    'Los gatos también tienen bigotes encima de los ojos y alrededor de la barbilla.',
    'Los gatos son curiosos por naturaleza y disfrutan explorando lugares nuevos.',
    'El corazón de un gato normalmente late más rápido que el de una persona.',
    'Los gatos pueden utilizar la postura corporal para comunicarse.',
    'Los gatos pueden ver mejor que los humanos con poca luz.',
    'Las uñas de un gato pueden retraerse parcialmente dentro de sus patas.',
    'Los gatos pueden cambiar de dirección muy rápidamente al correr.',
    'El sentido del olfato de un gato es mucho más fuerte que el de un humano.',
    'Los gatos pueden aprender rutinas observando su entorno.',
    'Los gatos pueden mover la cola de diferentes maneras para expresar emociones.',
    'Los gatos tienen buena memoria, especialmente en lugares conocidos.',
    'Las patas de los gatos tienen nervios sensibles que les ayudan a explorar.',
    'Los gatos suelen estirarse después de descansar.',
    'Una capa reflectante en los ojos ayuda a los gatos a aprovechar mejor la poca luz.',
    'Los gatos pueden comunicarse con los humanos mediante diferentes sonidos de maullido.',
    'Los gatos pueden utilizar sus bigotes para calcular la cercanía de objetos.',
    'Los gatos pueden aprender a abrir puertas y recipientes sencillos.',
    'Las orejas de un gato pueden moverse de forma independiente.',
    'Los gatos suelen utilizar lugares altos para observar su entorno.',
    'El lenguaje corporal de un gato puede comunicar más que sus sonidos.',
    'Los gatos son muy buenos manteniendo el equilibrio sobre superficies estrechas.',
    'Los gatos pueden dormir en varios periodos cortos en lugar de uno largo.',
  ];

  // ==========================================================
  // 🇫🇷 FRANÇAIS
  // ==========================================================

  static const List<String> fr = [
    'Les chats dorment généralement entre 12 et 16 heures par jour.',
    'Les chats peuvent sauter jusqu’à environ cinq fois la longueur de leur corps.',
    'Les moustaches aident les chats à évaluer l’espace autour d’eux.',
    'Les chats utilisent leur queue pour garder leur équilibre.',
    'Le motif du nez de chaque chat est unique.',
    'Les chats peuvent entendre des sons beaucoup plus aigus que les humains.',
    'Les chats peuvent ronronner même lorsqu’ils sont stressés.',
    'Les chats utilisent leurs oreilles pour exprimer leur humeur.',
    'Les chats ont généralement cinq doigts aux pattes avant et quatre aux pattes arrière.',
    'Les chats utilisent leur odorat pour explorer leur environnement.',
    'Les chats peuvent apprendre à reconnaître leur propre nom.',
    'Les pupilles d’un chat peuvent changer rapidement selon la quantité de lumière.',
    'Les chats passent une grande partie de leur temps éveillé à faire leur toilette.',
    'La langue du chat possède de petites structures en forme de crochets qui l’aident à entretenir son pelage.',
    'Les chats communiquent beaucoup entre eux grâce aux odeurs et au langage corporel.',
    'Le ronronnement peut aider un chat à se calmer.',
    'Les chats ont un excellent sens de l’équilibre.',
    'Les chats peuvent reconnaître les personnes familières à leur voix.',
    'Les chats ont aussi des moustaches au-dessus des yeux et autour du menton.',
    'Les chats sont naturellement curieux et aiment explorer de nouveaux endroits.',
    'Le cœur d’un chat bat normalement plus vite que celui d’un humain.',
    'Les chats peuvent utiliser leur posture pour communiquer.',
    'Les chats voient mieux que les humains dans une faible lumière.',
    'Les griffes d’un chat peuvent se rétracter partiellement dans ses pattes.',
    'Les chats peuvent changer très rapidement de direction lorsqu’ils courent.',
    'L’odorat d’un chat est beaucoup plus développé que celui d’un humain.',
    'Les chats peuvent apprendre des routines en observant leur environnement.',
    'Les chats peuvent bouger leur queue de différentes façons pour exprimer leurs émotions.',
    'Les chats ont une bonne mémoire, surtout dans les environnements familiers.',
    'Les coussinets des pattes des chats contiennent des nerfs sensibles qui les aident à explorer.',
    'Les chats s’étirent souvent après s’être reposés.',
    'Une couche réfléchissante dans leurs yeux aide les chats à utiliser efficacement la faible lumière.',
    'Les chats peuvent communiquer avec les humains grâce à différents types de miaulements.',
    'Les chats peuvent utiliser leurs moustaches pour évaluer la proximité des objets.',
    'Les chats peuvent apprendre à ouvrir des portes et des récipients simples.',
    'Les oreilles d’un chat peuvent bouger indépendamment l’une de l’autre.',
    'Les chats utilisent souvent les endroits élevés pour observer leur environnement.',
    'Le langage corporel d’un chat peut communiquer plus que ses vocalisations.',
    'Les chats sont très doués pour garder leur équilibre sur des surfaces étroites.',
    'Les chats peuvent dormir en plusieurs périodes courtes plutôt qu’en une seule longue période.',
  ];

  // ==========================================================
  // 🇨🇳 中文
  // ==========================================================

  static const List<String> zh = [
    '猫通常每天会睡大约12到16个小时。',
    '猫的跳跃高度可以达到自己身体长度的大约五倍。',
    '猫的胡须可以帮助它判断周围空间的大小。',
    '猫会利用尾巴帮助自己保持平衡。',
    '每只猫的鼻纹都是独一无二的。',
    '猫能听到比人类高得多的声音。',
    '猫即使感到压力时也可能会发出呼噜声。',
    '猫会通过耳朵表达自己的情绪。',
    '猫的前爪通常有五个脚趾，后爪通常有四个。',
    '猫会利用嗅觉探索周围的环境。',
    '猫可以学会辨认自己的名字。',
    '猫的瞳孔会根据光线强弱迅速变化。',
    '猫清醒时会花很多时间整理自己的毛发。',
    '猫的舌头上有细小的钩状结构，可以帮助清洁毛发。',
    '猫之间会通过气味和肢体语言进行交流。',
    '呼噜声有时可以帮助猫让自己平静下来。',
    '猫拥有非常好的平衡能力。',
    '猫可以通过声音认出熟悉的人。',
    '猫的眼睛上方和下巴附近也有胡须。',
    '猫天生好奇，喜欢探索新的地方。',
    '猫的心跳通常比人类更快。',
    '猫可以利用身体姿势与其他猫交流。',
    '猫在昏暗的环境中通常比人类看得更好。',
    '猫的爪子可以部分收回到脚掌中。',
    '猫奔跑时可以非常快速地改变方向。',
    '猫的嗅觉比人类灵敏得多。',
    '猫可以通过观察环境学习日常规律。',
    '猫可以用不同的尾巴动作表达不同的情绪。',
    '猫在熟悉的环境中通常拥有很好的记忆力。',
    '猫的脚掌上有敏感的神经，可以帮助它探索环境。',
    '猫休息后经常会伸展身体。',
    '猫眼睛中的反光层可以帮助它更好地利用微弱光线。',
    '猫可以通过不同的叫声与人类交流。',
    '猫可以利用胡须判断附近物体的距离。',
    '猫可以学会打开简单的门或容器。',
    '猫的两只耳朵可以独立转动。',
    '猫经常选择较高的位置观察周围环境。',
    '猫的肢体语言有时比声音表达的信息更多。',
    '猫在狭窄的表面上也能很好地保持平衡。',
    '猫可能会把睡眠分成多个较短的时间段。',
  ];

  // ==========================================================
  // 🇻🇳 TIẾNG VIỆT
  // ==========================================================

  static const List<String> vi = [
    'Mèo thường ngủ khoảng 12–16 giờ mỗi ngày.',
    'Mèo có thể nhảy cao khoảng gấp năm lần chiều dài cơ thể.',
    'Râu mèo giúp chúng ước lượng không gian xung quanh cơ thể.',
    'Mèo sử dụng đuôi để giúp giữ thăng bằng.',
    'Mỗi con mèo có một hoa văn mũi riêng biệt.',
    'Mèo có thể nghe được những âm thanh cao hơn nhiều so với con người.',
    'Mèo có thể kêu gừ gừ ngay cả khi đang căng thẳng.',
    'Mèo sử dụng tai để thể hiện tâm trạng.',
    'Mèo thường có năm ngón ở chân trước và bốn ngón ở chân sau.',
    'Mèo sử dụng khứu giác để khám phá môi trường xung quanh.',
    'Mèo có thể học cách nhận biết tên của mình.',
    'Đồng tử của mèo có thể thay đổi nhanh chóng tùy theo lượng ánh sáng.',
    'Mèo dành nhiều thời gian khi thức để tự chải chuốt bộ lông.',
    'Lưỡi mèo có những cấu trúc nhỏ giống móc câu giúp chăm sóc lông.',
    'Mèo giao tiếp với nhau bằng mùi hương và ngôn ngữ cơ thể.',
    'Tiếng gừ gừ đôi khi giúp mèo tự bình tĩnh.',
    'Mèo có khả năng giữ thăng bằng rất tốt.',
    'Mèo có thể nhận ra người quen qua giọng nói.',
    'Mèo cũng có râu phía trên mắt và quanh cằm.',
    'Mèo vốn tò mò và thích khám phá những nơi mới.',
    'Tim của mèo thường đập nhanh hơn tim người.',
    'Mèo có thể sử dụng tư thế cơ thể để giao tiếp.',
    'Mèo có thể nhìn tốt hơn con người trong điều kiện ánh sáng yếu.',
    'Móng vuốt của mèo có thể thu một phần vào bàn chân.',
    'Mèo có thể đổi hướng rất nhanh khi chạy.',
    'Khứu giác của mèo nhạy hơn con người rất nhiều.',
    'Mèo có thể học các thói quen bằng cách quan sát môi trường.',
    'Mèo có thể sử dụng nhiều chuyển động khác nhau của đuôi để thể hiện cảm xúc.',
    'Mèo có trí nhớ tốt, đặc biệt trong môi trường quen thuộc.',
    'Bàn chân mèo có các dây thần kinh nhạy cảm giúp chúng khám phá môi trường.',
    'Mèo thường duỗi người sau khi nghỉ ngơi.',
    'Một lớp phản chiếu trong mắt giúp mèo tận dụng ánh sáng yếu tốt hơn.',
    'Mèo có thể giao tiếp với con người bằng nhiều kiểu tiếng kêu khác nhau.',
    'Mèo có thể dùng râu để ước lượng khoảng cách tới các vật thể.',
    'Mèo có thể học cách mở những cánh cửa hoặc hộp đơn giản.',
    'Tai của mèo có thể di chuyển độc lập với nhau.',
    'Mèo thường thích những nơi cao để quan sát xung quanh.',
    'Ngôn ngữ cơ thể của mèo đôi khi truyền tải nhiều thông tin hơn tiếng kêu.',
    'Mèo rất giỏi giữ thăng bằng trên những bề mặt hẹp.',
    'Mèo có thể ngủ thành nhiều khoảng thời gian ngắn thay vì một giấc dài.',
  ];

  // ==========================================================
  // 🇯🇵 日本語
  // ==========================================================

  static const List<String> ja = [
    '猫は通常、1日に12〜16時間ほど眠ります。',
    '猫は自分の体長の約5倍の高さまでジャンプできることがあります。',
    '猫のひげは、周囲の空間を判断するのに役立ちます。',
    '猫はしっぽを使ってバランスを保ちます。',
    '猫の鼻の模様は一匹ずつ異なります。',
    '猫は人間よりもはるかに高い音を聞くことができます。',
    '猫はストレスを感じているときにもゴロゴロと喉を鳴らすことがあります。',
    '猫は耳を使って気分を表現します。',
    '猫は通常、前足に5本、後ろ足に4本の指があります。',
    '猫は嗅覚を使って周囲の環境を調べます。',
    '猫は自分の名前を覚えることができます。',
    '猫の瞳孔は光の量によって素早く変化します。',
    '猫は起きている時間の多くを毛づくろいに使います。',
    '猫の舌には小さなフックのような構造があり、毛づくろいに役立ちます。',
    '猫同士は匂いやボディランゲージを使ってコミュニケーションします。',
    'ゴロゴロという音は猫自身を落ち着かせるのに役立つことがあります。',
    '猫は非常に優れたバランス感覚を持っています。',
    '猫は声を聞いて知っている人を認識できます。',
    '猫には目の上やあごの周りにもひげがあります。',
    '猫は生まれつき好奇心が強く、新しい場所を探検するのが好きです。',
    '猫の心拍数は通常、人間より速いです。',
    '猫は体の姿勢を使って他の猫と意思疎通できます。',
    '猫は暗い場所では人間よりよく見えることがあります。',
    '猫の爪は足の中に部分的に引っ込めることができます。',
    '猫は走っているときに非常に素早く方向を変えられます。',
    '猫の嗅覚は人間よりはるかに優れています。',
    '猫は周囲を観察することで日常の習慣を学ぶことができます。',
    '猫はしっぽの動きによってさまざまな感情を表現できます。',
    '猫は特に慣れた環境では良い記憶力を持っています。',
    '猫の足には敏感な神経があり、周囲を調べるのに役立ちます。',
    '猫は休んだ後によく体を伸ばします。',
    '猫の目にある反射層は、弱い光を効率よく利用するのに役立ちます。',
    '猫はさまざまな鳴き声を使って人間とコミュニケーションできます。',
    '猫はひげを使って近くにある物体との距離を判断できます。',
    '猫は簡単なドアや容器を開ける方法を学ぶことがあります。',
    '猫の耳は左右それぞれ独立して動かすことができます。',
    '猫は高い場所から周囲を観察することを好むことがあります。',
    '猫のボディランゲージは鳴き声以上の情報を伝えることがあります。',
    '猫は狭い場所でも上手にバランスを取ることができます。',
    '猫は長い睡眠を一度に取るのではなく、短い睡眠を何度も取ることがあります。',
  ];

  // ==========================================================
  // 🐱 GET FACT FOR LANGUAGE AND DAY
  // ==========================================================

  static String getDailyFact({
    required String languageCode,
    DateTime? date,
  }) {
    final DateTime day = date ?? DateTime.now();

    final int dayIndex =
        DateTime.utc(
          day.year,
          day.month,
          day.day,
        ).difference(
          DateTime.utc(
            2026,
            1,
            1,
          ),
        ).inDays;

    final List<String> facts = _factsForLanguage(
      languageCode,
    );

    final int index =
        dayIndex.abs() % facts.length;

    return facts[index];
  }

  // ==========================================================
  // 🌍 LANGUAGE SELECTION
  // ==========================================================

  static List<String> _factsForLanguage(
    String languageCode,
  ) {
    switch (languageCode) {
      case 'fi':
        return fi;

      case 'en':
        return en;

      case 'de':
        return de;

      case 'es':
        return es;

      case 'fr':
        return fr;

      case 'zh':
        return zh;

      case 'vi':
        return vi;

      case 'ja':
        return ja;

      default:
        return en;
    }
  }
}