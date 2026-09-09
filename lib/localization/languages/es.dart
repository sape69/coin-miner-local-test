const Map<String, String> esTranslations = {
  // ============================================================
  // 🌍 GENERAL
  // ============================================================

  'appTitle': 'STELLURIINI',
  'home': 'Inicio',
  'about': 'Acerca de',
  'history': 'Historial de transacciones',
  'roadmap': 'Hoja de ruta',
  'token': 'Token STL',
  'tokenomics': 'Tokenómica',
  'whitepaper': 'Whitepaper',
  'language': 'Idioma',
  'logout': 'Cerrar sesión',
  'menu': 'Menú',

  // ============================================================
  // 💰 BALANCE / MINING
  // ============================================================

  'balance': 'Saldo',
  'mining': 'Minería',
  'miningRate': 'Tasa de minería',
  'hashRate': 'Tasa de hash',
  'effectiveHashRate': 'Tasa de hash efectiva',
  'effectiveHashRateLabel': 'Tasa de hash efectiva',

  'dailyHashRateLabel': 'Tasa de hash diaria',
  'dailyHashRateDay': 'Día {day}',
  'dailyHashRateMaximum': 'Máximo: {rate} HR',
  'dailyHashRateSuccess': 'Tasa de hash del día {day}: {rate} HR',

  'stellaMiningProgress': 'Progreso de minería de Stella',
  'stlPerHour': 'STL por hora',
  'hashRateBonus': 'Bono de tasa de hash',

  'startMining': 'INICIAR MINERÍA',
  'claimMining': 'RECLAMAR STL',
  'miningActive': 'Minería activa',
  'miningComplete': 'Ciclo de minería completado',

  'timeRemaining': 'Tiempo restante',
  'remaining': 'Tiempo restante: {time}',

  'streak': 'Racha',
  'days': 'días',

  // ============================================================
  // 🎁 DAILY BONUS
  // ============================================================

  'dailyBonus': 'Bono diario',
  'dailyClaim': 'Reclamar bono diario',
  'dailyReward': 'Recompensa diaria',
  'claimedToday': 'Reclamado hoy',
  'alreadyClaimed':
      'Ya has reclamado la recompensa de hoy.',

  // ============================================================
  // 📺 ADS
  // ============================================================

  'watchAd': 'VER ANUNCIO',
  'watchAndEarn': 'VER Y GANAR',
  'loadingAd': 'CARGANDO ANUNCIO...',
  'adLoading': 'CARGANDO ANUNCIO...',
  'adReward': '+{amount} HR',

  // ============================================================
  // ⚡ STELLA POWER BOOST
  // ============================================================

  'powerBoost': 'Stella Power Boost',

  'powerBoostOffer':
      'Mira un anuncio para activar +{amount} HR de Stella Power Boost durante 4 horas.',

  'powerBoostActive':
      'Power Boost activo',

  'powerBoostActiveTitle':
      '¡Stella Power Boost está activo!',

  'powerBoostActiveMessage':
      '+{amount} HR está activo durante tu ciclo de minería.',

  'powerBoostAlreadyActive':
      'Power Boost ya está activo.',

  'nextPowerBoostMessage':
      'El próximo Power Boost estará disponible cuando termine el actual.',

  'nextAdAfterBoost':
      'El próximo anuncio estará disponible después de que termine el boost.',

  'maxBoostsInfo':
      'Puedes activar hasta {count} Power Boosts al día.',

  'adsToday':
      'Anuncios hoy: {current}/{max}',

  'dailyLimitReached':
      'Se alcanzó el límite diario de anuncios.',

  'powerBoostReward':
      'Stella Power Boost: +{amount} HR',

  'adRewardDuplicate':
      'Esta recompensa publicitaria ya fue procesada.',

  'testAdRewardFailed':
      'No se pudo procesar la recompensa publicitaria.',

  // ============================================================
  // 🌐 SERVER
  // ============================================================

  'serverConnectionFailed':
      'Error de conexión con el servidor.',

  'refresh':
      'Actualizar',

  // ============================================================
  // 👤 GENERAL UI
  // ============================================================

  'profile':
      'Perfil',

  'comingSoon':
      'Próximamente',

  'information':
      'Información',

  // ============================================================
  // 🐱 STELLA
  // ============================================================

  'catFact':
      'Dato gatuno de Stella',

  'stellaFacts':
      'Dato gatuno de Stella',

  'stellaPower':
      'Stella Power',

  'stellaMining':
      'Stella Mining',

  'stellaIsMining':
      'Stella está minando',

  'stellaMiningNow':
      'Stella está minando ahora',

  'stellaIsResting':
      'Stella está descansando',

  'stellaWaiting':
      'Stella está esperando el próximo ciclo de minería',

  'stlReadyToCollect':
      'STL está listo para reclamar',

  'stlMined':
      'STL MINADO',

  'waitingForStella':
      'Esperando a Stella',

  'stellaIsWorking':
      'STELLA ESTÁ TRABAJANDO...',

  'stellaIsMiningButton':
      'MINERÍA ACTIVA',

  'stellaAlreadyMining':
      'Stella ya está minando.',

  'prepareAd':
      'Preparando anuncio...',

  'miningCollected':
      'Recolectado {amount} STL',

  'miningStartFailed':
      'No se pudo iniciar la minería.',

  // ============================================================
  // 💎 TRANSACTIONS
  // ============================================================

  'transactions':
      'Transacciones',

  'noTransactions':
      'Aún no hay transacciones.',

  'totalStl':
      'STL total',

  'points':
      'puntos',

  'pointsAdded':
      'Puntos añadidos',

  // ============================================================
  // 🔄 TEST ACCOUNT
  // ============================================================

  'resetAccount':
      'Restablecer cuenta de prueba',

  'resetConfirm':
      '¿Seguro que quieres restablecer la cuenta de prueba?',

  'cancel':
      'Cancelar',

  'reset':
      'Restablecer',

  'error':
      'Error',

  'success':
      'Éxito',

  'close':
      'Cerrar',

  // ============================================================
  // 🔐 LOGIN
  // ============================================================

  'email':
      'Correo electrónico',

  'password':
      'Contraseña',

  'forgotPassword':
      '¿Olvidaste tu contraseña?',

  'login':
      'INICIAR SESIÓN',

  'loggingIn':
      'INICIANDO SESIÓN...',

  'createAccount':
      '¿Aún no tienes cuenta? Crear una nueva cuenta',

  'loginFillFields':
      'Introduce tu correo electrónico y contraseña.',

  'loginInvalidEmail':
      'La dirección de correo electrónico no es válida.',

  'loginUserNotFound':
      'No se encontró el usuario.',

  'loginInvalidCredentials':
      'El correo electrónico o la contraseña son incorrectos.',

  'loginUserDisabled':
      'Esta cuenta de usuario ha sido deshabilitada.',

  'loginTooManyRequests':
      'Demasiados intentos. Inténtalo de nuevo más tarde.',

  'loginNetworkError':
      'Error de conexión de red.',

  'loginFailed':
      'Error al iniciar sesión',

  // ============================================================
  // 📝 REGISTER
  // ============================================================

  'confirmPassword':
      'Confirmar contraseña',

  'passwordsDoNotMatch':
      'Las contraseñas no coinciden.',

  'passwordTooShort':
      'La contraseña debe tener al menos 6 caracteres.',

  'creatingAccount':
      'CREANDO CUENTA...',

  'accountCreated':
      'Cuenta creada correctamente.',

  'emailAlreadyInUse':
      'Esta dirección de correo electrónico ya está en uso.',

  'passwordTooWeak':
      'La contraseña es demasiado débil.',

  'registrationNotAllowed':
      'El registro no está permitido actualmente.',

  'registrationFailed':
      'No se pudo crear la cuenta.',

  // ============================================================
  // 🔑 FORGOT PASSWORD
  // ============================================================

  'passwordResetSent':
      'El enlace para restablecer la contraseña se ha enviado a tu correo electrónico.',

  'passwordResetUserNotFound':
      'No se encontró ninguna cuenta de usuario para esta dirección de correo electrónico.',

  'passwordResetNotAllowed':
      'El restablecimiento de contraseña no está permitido actualmente.',

  'passwordResetFailed':
      'No se pudo restablecer la contraseña.',

  'passwordResetDescription':
      'Introduce la dirección de correo electrónico de tu cuenta y te enviaremos un enlace para restablecer tu contraseña.',

  'sending':
      'ENVIANDO...',

  'sendPasswordReset':
      'ENVIAR ENLACE PARA RESTABLECER',

  // ============================================================
  // 📜 TRANSACTION HISTORY
  // ============================================================

  'transactionHistory':
      'Historial de transacciones',

  'stellaActivity':
      'ACTIVIDAD DE STELLA',

  'latestTransactions':
      '{count} transacciones recientes',

  'dailyStellaBonus':
      'Bono diario de Stella',

  'dailyBonusDescription':
      'Bono diario de Stella',

  'stellaAdReward':
      'Recompensa de anuncio de Stella',

  'adRewardDescription':
      'Recompensa por ver un anuncio',

  'stlTransaction':
      'Transacción STL',

  'stelluriiniActivity':
      'Actividad de Stelluriini',

  'transactionBalance':
      'Saldo: {balance} STL',

  'tryAgain':
      'Intentar de nuevo',

  'noTransactionsYet':
      'Aún no hay transacciones',

  'rewardsAppearHere':
      'Tus recompensas STL aparecerán aquí. 🐱',

  'startMiningWithStella':
      'Empieza a minar con Stella',

  'historyRecorded':
      'La minería, los bonos diarios y las recompensas por anuncios se registrarán aquí.',

  'stellaCheckingHistory':
      'Stella está revisando tu historial...',

  'everyRewardJourney':
      'Cada recompensa forma parte de tu viaje con Stelluriini. 🐾',

  // ============================================================
  // ℹ️ ABOUT
  // ============================================================

  'aboutWelcome':
      'Bienvenido a Stelluriini',

  'aboutWelcomeDescription':
      'Stelluriini es un proyecto comunitario basado en Solana, donde la gata Stella actúa como mascota y guía del proyecto.',

  'aboutDescription':
      'Stelluriini combina una comunidad, un token digital y una experiencia de aplicación creada alrededor de Stella.',

  'meetStella':
      'Conoce a Stella',

  'aboutStellaIntro':
      'Stella es el corazón de Stelluriini y la adorable mascota felina del proyecto.',

  'aboutStellaDescription':
      'Stella guía a los usuarios a través de la minería, las recompensas y el ecosistema Stelluriini.',

  'community':
      'Comunidad',

  'aboutCommunityDescription':
      'Stelluriini se construye alrededor de su comunidad. El objetivo es crear un ecosistema abierto, divertido y accesible.',

  'builtOnSolana':
      'Construido sobre Solana',

  'aboutSolanaDescription':
      'Stelluriini utiliza la blockchain de Solana, proporcionando un entorno rápido y rentable para el token STL.',

  'stlToken':
      'Token STL',

  'importantInformation':
      'Información importante',

  'aboutImportantDescription':
      'El saldo STL que se muestra actualmente en la aplicación representa puntos virtuales dentro de la aplicación. El saldo no es automáticamente una criptomoneda retirable.',

  // ============================================================
  // 🗺️ ROADMAP
  // ============================================================

  'roadmapTitle':
      'Hoja de ruta de Stelluriini',

  'roadmapSubtitle':
      'El viaje de Stelluriini, paso a paso.',

  'roadmapPhase1':
      'Fase 1 – Fundación',

  'roadmapPhase1Title':
      'Construcción de Stelluriini',

  'roadmapPhase1Description':
      'Creación del proyecto Stelluriini, el token STL y la mascota Stella.',

  'roadmapPhase2':
      'Fase 2 – Aplicación',

  'roadmapPhase2Title':
      'Desarrollo de la aplicación Stelluriini',

  'roadmapPhase2Description':
      'Minería, recompensas diarias, Stella Power Boost e historial de transacciones.',

  'roadmapPhase3':
      'Fase 3 – Comunidad',

  'roadmapPhase3Title':
      'Crecimiento de la comunidad',

  'roadmapPhase3Description':
      'Construcción de la comunidad, recopilación de comentarios y desarrollo de la marca Stelluriini.',

  'roadmapPhase4':
      'Fase 4 – Ecosistema',

  'roadmapPhase4Title':
      'Expansión del ecosistema STL',

  'roadmapPhase4Description':
      'Desarrollo de casos de uso para el token STL y expansión del ecosistema Stelluriini.',

  'roadmapPhase5':
      'Fase 5 – Futuro',

  'roadmapPhase5Title':
      'La siguiente etapa de Stelluriini',

  'roadmapPhase5Description':
      'Exploración de nuevas funciones, posibles colaboraciones e ideas de la comunidad.',

  // ============================================================
  // 🪙 TOKEN
  // ============================================================

  'tokenTitle':
      'Stelluriini STL',

  'tokenSubtitle':
      'El token oficial de Stelluriini en la red Solana.',

  'tokenName':
      'Nombre',

  'tokenSymbol':
      'Símbolo',

  'tokenBlockchain':
      'Blockchain',

  'tokenSupply':
      'Suministro total',

  'tokenMint':
      'Dirección Mint',

  'tokenDescription':
      'Stelluriini es un token impulsado por la comunidad en la blockchain de Solana.',

  'solana':
      'Solana',

  'copyAddress':
      'Copiar dirección',

  'addressCopied':
      'Dirección copiada.',

  // ============================================================
  // 📊 TOKENOMICS
  // ============================================================

  'tokenomicsTitle':
      'Tokenómica de STL',

  'tokenomicsSubtitle':
      'Información básica y estructura económica del token Stelluriini STL.',

  'totalSupply':
      'Suministro total',

  'tokenAllocation':
      'Distribución de tokens',

  'communityAllocation':
      'Comunidad',

  'ecosystemAllocation':
      'Ecosistema',

  'developmentAllocation':
      'Desarrollo',

  'liquidityAllocation':
      'Liquidez',

  'marketingAllocation':
      'Marketing',

  'tokenomicsImportant':
      'Las asignaciones exactas de tokens pueden actualizarse durante el desarrollo del proyecto. Todos los cambios deben comunicarse de forma transparente a la comunidad.',

  // ============================================================
  // 📄 WHITEPAPER
  // ============================================================

  'whitepaperTitle':
      'Whitepaper de Stelluriini',

  'whitepaperSubtitle':
      'La visión, la tecnología y la dirección futura del proyecto Stelluriini.',

  'whitepaperIntroduction':
      'Introducción',

  'whitepaperVision':
      'Visión',

  'whitepaperMission':
      'Misión',

  'whitepaperTechnology':
      'Tecnología',

  'whitepaperMining':
      'Sistema de minería',

  'whitepaperStella':
      'Stella',

  'whitepaperToken':
      'Token STL',

  'whitepaperTokenomics':
      'Tokenómica',

  'whitepaperCommunity':
      'Comunidad',

  'whitepaperRoadmap':
      'Hoja de ruta',

  'whitepaperSecurity':
      'Seguridad',

  'whitepaperFuture':
      'Futuro',

  'whitepaperDisclaimer':
      'Este whitepaper es una descripción informativa del proyecto Stelluriini. Las funciones y los planes pueden cambiar durante el desarrollo.',

  // ============================================================
  // ⚠️ IMPORTANT INFORMATION
  // ============================================================

  'virtualPointsNotice':
      'Las recompensas STL que se muestran en la aplicación son actualmente puntos virtuales dentro de la aplicación.',

  'withdrawalsDisabled':
      'Los retiros no están disponibles actualmente.',

  'futureWithdrawals':
      'Un posible sistema futuro de retiros se diseñará por separado y sus condiciones se anunciarán antes de su implementación.',

  // ============================================================
  // 🐾 FOOTER
  // ============================================================

  'footerTagline':
      'Minando juntos por el futuro de Stelluriini.',

  'footerToken':
      'STL • STELLURIINI',
};