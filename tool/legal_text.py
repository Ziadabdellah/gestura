CONTACT = "ziadabdellah64@gmail.com"
CONTROLLER = "Ziad Abdellah"
UPDATED = "2026-11-10"

LANGUAGES = {
    "en": ("English", "ltr"),
    "ar": ("العربية", "rtl"),
    "ru": ("Русский", "ltr"),
    "es": ("Español", "ltr"),
    "fr": ("Français", "ltr"),
    "de": ("Deutsch", "ltr"),
}

PRIVACY = {
    "en": {
        "title": "Gestura privacy policy",
        "updated": "Last updated: {date}",
        "sections": [
            ("Who is responsible", [
                "Gestura is made by {controller}, who is responsible for your personal data (the data controller). Write to {contact} about anything in this policy.",
            ]),
            ("The short version", [
                "No ads, and your data is never sold.",
                "Usage analytics and crash reports stay off unless you turn them on, and you can turn them off again at any time in Settings → Privacy.",
                "You can delete your account and your synced progress from the app at any time.",
            ]),
            ("What we process and why", [
                "Your account. When you continue as a guest, Firebase Authentication creates an anonymous user ID. If you create an account, it also stores your email address and a securely hashed password. We use them to sign you in and to keep your progress with your account. Legal basis: providing the service you asked for (Art. 6(1)(b) GDPR).",
                "Your learning progress: which lessons you finished, your best score and when. It is stored on your device and, while you are signed in, in Cloud Firestore in the European Union (multi-region eur3) under your user ID, so it is kept safe and follows you to your other devices. Legal basis: Art. 6(1)(b) GDPR.",
                "Your settings (app language, theme, daily goal, hand, reduced motion and your privacy choices) are stored only on your device.",
                "Crash reports, only if you turn them on. Firebase Crashlytics receives technical details when the app crashes or meets an error: the stack trace, device model, operating system and app version, and an installation identifier. Legal basis: your consent (Art. 6(1)(a) GDPR). Reports are kept for 90 days.",
                "Usage analytics, only if you turn them on. Google Analytics for Firebase receives a small set of events (onboarding finished, signed up or in, lesson finished with its score), an app instance ID, the device and app version, and your approximate country derived from your IP address. Advertising IDs are not collected and ad personalisation is off. Legal basis: your consent (Art. 6(1)(a) GDPR). Data is kept for 2 months.",
                "Sign videos and images are delivered by Firebase Hosting. Like any web server, it processes your IP address to send you the files.",
            ]),
            ("Who processes data for us", [
                "Google Ireland Limited and Google LLC provide Firebase and process data on our behalf under the Firebase data processing terms. Some data may be processed in the United States; Google relies on the EU–US Data Privacy Framework and the European Commission's Standard Contractual Clauses.",
            ]),
            ("How long we keep it", [
                "Your account and synced progress: until you delete your account. Crash reports: 90 days. Usage analytics: 2 months. Data on your device: until you delete the app or your account.",
            ]),
            ("Your rights", [
                "You can ask for access to your data, for its correction or deletion, for a copy in a portable format, and you can restrict or object to processing. You can withdraw consent at any time in Settings → Privacy; this does not affect processing that happened before. You can also complain to the data protection authority of the EU country where you live.",
            ]),
            ("Deleting your account", [
                "In the app, open Profile → Delete account. Your account and your synced progress are deleted right away. Without the app, follow the steps on {delete_url}.",
            ]),
            ("Children", [
                "Gestura is not directed at children under 13. If you believe a child has given us personal data, write to {contact} and we will delete it.",
            ]),
            ("Security", [
                "Data is encrypted in transit and at rest. Database rules only let you read and change your own data.",
            ]),
            ("Changes", [
                "If this policy changes, we update this page and its date, and we tell you in the app about important changes.",
            ]),
        ],
    },
    "ar": {
        "title": "سياسة الخصوصية في Gestura",
        "updated": "آخر تحديث: {date}",
        "sections": [
            ("المسؤول عن بياناتك", [
                "يطوّر Gestura {controller}، وهو المسؤول عن بياناتك الشخصية (المتحكّم في البيانات). راسلنا على {contact} بخصوص أي شيء في هذه السياسة.",
            ]),
            ("باختصار", [
                "لا إعلانات، ولا نبيع بياناتك أبدًا.",
                "إحصاءات الاستخدام وتقارير الأعطال متوقفة ما لم تشغّلها بنفسك، ويمكنك إيقافها في أي وقت من الإعدادات ← الخصوصية.",
                "يمكنك حذف حسابك وتقدّمك المتزامن من داخل التطبيق في أي وقت.",
            ]),
            ("ما الذي نعالجه ولماذا", [
                "حسابك. عند المتابعة كضيف ينشئ Firebase Authentication معرّف مستخدم مجهول الهوية. وإذا أنشأت حسابًا فإنه يحفظ أيضًا بريدك الإلكتروني وكلمة مرور مشفّرة بشكل آمن. نستخدمها لتسجيل دخولك وحفظ تقدّمك مع حسابك. الأساس القانوني: تقديم الخدمة التي طلبتها (المادة 6(1)(ب) من اللائحة العامة لحماية البيانات).",
                "تقدّمك في التعلّم: الدروس التي أنهيتها وأفضل نتيجة وتوقيتها. يُحفظ على جهازك، وأثناء تسجيل دخولك يُحفظ أيضًا في Cloud Firestore داخل الاتحاد الأوروبي (المنطقة المتعددة eur3) تحت معرّف المستخدم الخاص بك، ليبقى آمنًا ويرافقك على أجهزتك الأخرى. الأساس القانوني: المادة 6(1)(ب).",
                "إعداداتك (لغة التطبيق والسمة والهدف اليومي واليد وتقليل الحركة واختيارات الخصوصية) تُحفظ على جهازك فقط.",
                "تقارير الأعطال، فقط إذا شغّلتها. يتلقى Firebase Crashlytics تفاصيل تقنية عند تعطّل التطبيق أو حدوث خطأ: مسار الخطأ وطراز الجهاز ونظام التشغيل وإصدار التطبيق ومعرّف التثبيت. الأساس القانوني: موافقتك (المادة 6(1)(أ)). تُحفظ التقارير 90 يومًا.",
                "إحصاءات الاستخدام، فقط إذا شغّلتها. يتلقى Google Analytics for Firebase عددًا قليلًا من الأحداث (إنهاء الإعداد الأولي، إنشاء حساب أو تسجيل الدخول، إنهاء درس مع نتيجته) ومعرّف نسخة التطبيق وإصدار الجهاز والتطبيق وبلدك التقريبي المستنتج من عنوان IP. لا نجمع معرّفات الإعلانات، وتخصيص الإعلانات متوقف. الأساس القانوني: موافقتك (المادة 6(1)(أ)). تُحفظ البيانات شهرين.",
                "تُرسل فيديوهات الإشارات وصورها عبر Firebase Hosting، ومثل أي خادم ويب يعالج عنوان IP الخاص بك لإرسال الملفات إليك.",
            ]),
            ("من يعالج البيانات نيابة عنا", [
                "توفّر Google Ireland Limited وGoogle LLC خدمة Firebase وتعالجان البيانات نيابة عنا وفق شروط معالجة البيانات في Firebase. قد تُعالج بعض البيانات في الولايات المتحدة، وتعتمد Google على إطار خصوصية البيانات بين الاتحاد الأوروبي والولايات المتحدة والبنود التعاقدية القياسية للمفوضية الأوروبية.",
            ]),
            ("مدة الاحتفاظ", [
                "حسابك وتقدّمك المتزامن: حتى تحذف حسابك. تقارير الأعطال: 90 يومًا. إحصاءات الاستخدام: شهران. البيانات على جهازك: حتى تحذف التطبيق أو حسابك.",
            ]),
            ("حقوقك", [
                "يحق لك طلب الوصول إلى بياناتك وتصحيحها أو حذفها والحصول على نسخة منها بصيغة قابلة للنقل، كما يحق لك تقييد المعالجة أو الاعتراض عليها. يمكنك سحب موافقتك في أي وقت من الإعدادات ← الخصوصية، دون أن يؤثر ذلك على المعالجة السابقة. ويمكنك أيضًا تقديم شكوى إلى هيئة حماية البيانات في دولة الاتحاد الأوروبي التي تعيش فيها.",
            ]),
            ("حذف حسابك", [
                "في التطبيق افتح الملف الشخصي ← حذف الحساب، فيُحذف حسابك وتقدّمك المتزامن فورًا. ومن دون التطبيق اتبع الخطوات في {delete_url}.",
            ]),
            ("الأطفال", [
                "Gestura غير موجّه للأطفال دون 13 عامًا. إذا كنت تعتقد أن طفلًا أعطانا بيانات شخصية فراسلنا على {contact} وسنحذفها.",
            ]),
            ("الأمان", [
                "البيانات مشفّرة أثناء النقل والتخزين، وقواعد قاعدة البيانات تسمح لك فقط بقراءة بياناتك وتغييرها.",
            ]),
            ("التغييرات", [
                "إذا تغيّرت هذه السياسة نحدّث هذه الصفحة وتاريخها، ونخبرك داخل التطبيق بالتغييرات المهمة.",
            ]),
        ],
    },
    "ru": {
        "title": "Политика конфиденциальности Gestura",
        "updated": "Последнее обновление: {date}",
        "sections": [
            ("Кто отвечает за данные", [
                "Gestura создаёт {controller}, он отвечает за ваши персональные данные (контролёр данных). По любым вопросам об этой политике пишите на {contact}.",
            ]),
            ("Коротко", [
                "Никакой рекламы, и мы никогда не продаём ваши данные.",
                "Статистика использования и отчёты о сбоях выключены, пока вы сами их не включите, и их можно выключить в любой момент в разделе «Настройки → Конфиденциальность».",
                "Вы можете удалить аккаунт и синхронизированный прогресс в приложении в любой момент.",
            ]),
            ("Что мы обрабатываем и зачем", [
                "Ваш аккаунт. Когда вы продолжаете как гость, Firebase Authentication создаёт анонимный идентификатор пользователя. Если вы создаёте аккаунт, сохраняются также адрес электронной почты и надёжно захешированный пароль. Мы используем их, чтобы вы могли войти, и чтобы прогресс сохранялся в аккаунте. Правовое основание: предоставление запрошенной услуги (ст. 6(1)(b) GDPR).",
                "Ваш прогресс: какие уроки вы прошли, лучший результат и когда. Он хранится на устройстве, а пока вы вошли в аккаунт, ещё и в Cloud Firestore в Европейском союзе (мультирегион eur3) под вашим идентификатором, чтобы он был в сохранности и был доступен на других устройствах. Правовое основание: ст. 6(1)(b) GDPR.",
                "Ваши настройки (язык приложения, тема, цель на день, рука, уменьшение движения и выбор конфиденциальности) хранятся только на устройстве.",
                "Отчёты о сбоях, только если вы их включили. Firebase Crashlytics получает технические данные при сбое или ошибке: трассировку стека, модель устройства, версию операционной системы и приложения, идентификатор установки. Правовое основание: ваше согласие (ст. 6(1)(a) GDPR). Отчёты хранятся 90 дней.",
                "Статистика использования, только если вы её включили. Google Analytics for Firebase получает небольшой набор событий (завершение начальной настройки, регистрация или вход, завершение урока с результатом), идентификатор экземпляра приложения, версию устройства и приложения и примерную страну по IP-адресу. Рекламные идентификаторы не собираются, персонализация рекламы выключена. Правовое основание: ваше согласие (ст. 6(1)(a) GDPR). Данные хранятся 2 месяца.",
                "Видео и изображения жестов передаются через Firebase Hosting. Как любой веб-сервер, он обрабатывает ваш IP-адрес, чтобы отправить файлы.",
            ]),
            ("Кто обрабатывает данные по нашему поручению", [
                "Google Ireland Limited и Google LLC предоставляют Firebase и обрабатывают данные по нашему поручению на условиях обработки данных Firebase. Часть данных может обрабатываться в США; Google опирается на Рамочную программу конфиденциальности данных ЕС–США и стандартные договорные условия Европейской комиссии.",
            ]),
            ("Сколько мы храним данные", [
                "Аккаунт и синхронизированный прогресс: пока вы не удалите аккаунт. Отчёты о сбоях: 90 дней. Статистика использования: 2 месяца. Данные на устройстве: пока вы не удалите приложение или аккаунт.",
            ]),
            ("Ваши права", [
                "Вы можете запросить доступ к своим данным, их исправление или удаление, копию в переносимом формате, а также ограничить обработку или возразить против неё. Согласие можно отозвать в любой момент в разделе «Настройки → Конфиденциальность»; это не влияет на обработку, которая была до этого. Вы также можете подать жалобу в орган по защите данных страны ЕС, где вы живёте.",
            ]),
            ("Удаление аккаунта", [
                "В приложении откройте «Профиль → Удалить аккаунт». Аккаунт и синхронизированный прогресс удаляются сразу. Без приложения следуйте инструкции на странице {delete_url}.",
            ]),
            ("Дети", [
                "Gestura не предназначена для детей младше 13 лет. Если вы считаете, что ребёнок передал нам персональные данные, напишите на {contact}, и мы их удалим.",
            ]),
            ("Безопасность", [
                "Данные шифруются при передаче и хранении. Правила базы данных позволяют читать и изменять только ваши собственные данные.",
            ]),
            ("Изменения", [
                "Если политика изменится, мы обновим эту страницу и дату, а о важных изменениях сообщим в приложении.",
            ]),
        ],
    },
    "es": {
        "title": "Política de privacidad de Gestura",
        "updated": "Última actualización: {date}",
        "sections": [
            ("Quién es el responsable", [
                "Gestura lo desarrolla {controller}, responsable de tus datos personales (responsable del tratamiento). Escribe a {contact} para cualquier cuestión sobre esta política.",
            ]),
            ("En resumen", [
                "Sin anuncios y nunca vendemos tus datos.",
                "Las estadísticas de uso y los informes de errores están desactivados salvo que los actives, y puedes volver a desactivarlos cuando quieras en Ajustes → Privacidad.",
                "Puedes eliminar tu cuenta y tu progreso sincronizado desde la app en cualquier momento.",
            ]),
            ("Qué tratamos y por qué", [
                "Tu cuenta. Al continuar como invitado, Firebase Authentication crea un identificador de usuario anónimo. Si creas una cuenta, también guarda tu correo electrónico y una contraseña cifrada de forma segura. Los usamos para iniciar tu sesión y guardar tu progreso en tu cuenta. Base jurídica: prestar el servicio que solicitas (art. 6.1.b RGPD).",
                "Tu progreso: qué lecciones terminaste, tu mejor resultado y cuándo. Se guarda en tu dispositivo y, mientras tienes la sesión iniciada, también en Cloud Firestore en la Unión Europea (multirregión eur3) bajo tu identificador, para que esté seguro y te acompañe en tus otros dispositivos. Base jurídica: art. 6.1.b RGPD.",
                "Tus ajustes (idioma de la app, tema, meta diaria, mano, reducir movimiento y tus opciones de privacidad) se guardan solo en tu dispositivo.",
                "Informes de errores, solo si los activas. Firebase Crashlytics recibe datos técnicos cuando la app falla o encuentra un error: la traza de la pila, el modelo del dispositivo, la versión del sistema operativo y de la app, y un identificador de instalación. Base jurídica: tu consentimiento (art. 6.1.a RGPD). Los informes se conservan 90 días.",
                "Estadísticas de uso, solo si las activas. Google Analytics for Firebase recibe un pequeño conjunto de eventos (configuración inicial terminada, registro o inicio de sesión, lección terminada con su resultado), un identificador de instancia de la app, la versión del dispositivo y de la app, y tu país aproximado a partir de tu dirección IP. No se recogen identificadores de publicidad y la personalización de anuncios está desactivada. Base jurídica: tu consentimiento (art. 6.1.a RGPD). Los datos se conservan 2 meses.",
                "Los vídeos e imágenes de los signos se entregan mediante Firebase Hosting. Como cualquier servidor web, trata tu dirección IP para enviarte los archivos.",
            ]),
            ("Quién trata datos por encargo nuestro", [
                "Google Ireland Limited y Google LLC prestan Firebase y tratan datos por encargo nuestro según las condiciones de tratamiento de datos de Firebase. Algunos datos pueden tratarse en Estados Unidos; Google se acoge al Marco de Privacidad de Datos UE-EE. UU. y a las cláusulas contractuales tipo de la Comisión Europea.",
            ]),
            ("Cuánto tiempo los conservamos", [
                "Tu cuenta y tu progreso sincronizado: hasta que elimines tu cuenta. Informes de errores: 90 días. Estadísticas de uso: 2 meses. Datos en tu dispositivo: hasta que elimines la app o tu cuenta.",
            ]),
            ("Tus derechos", [
                "Puedes solicitar el acceso a tus datos, su rectificación o supresión y una copia en un formato portable, así como limitar el tratamiento u oponerte a él. Puedes retirar tu consentimiento en cualquier momento en Ajustes → Privacidad, sin que afecte al tratamiento anterior. También puedes reclamar ante la autoridad de protección de datos del país de la UE donde vives.",
            ]),
            ("Eliminar tu cuenta", [
                "En la app, abre Perfil → Eliminar cuenta. Tu cuenta y tu progreso sincronizado se eliminan al instante. Sin la app, sigue los pasos de {delete_url}.",
            ]),
            ("Menores", [
                "Gestura no está dirigida a menores de 13 años. Si crees que un menor nos ha dado datos personales, escribe a {contact} y los eliminaremos.",
            ]),
            ("Seguridad", [
                "Los datos se cifran en tránsito y en reposo. Las reglas de la base de datos solo te permiten leer y cambiar tus propios datos.",
            ]),
            ("Cambios", [
                "Si esta política cambia, actualizaremos esta página y su fecha, y te avisaremos en la app de los cambios importantes.",
            ]),
        ],
    },
    "fr": {
        "title": "Politique de confidentialité de Gestura",
        "updated": "Dernière mise à jour : {date}",
        "sections": [
            ("Qui est responsable", [
                "Gestura est développé par {controller}, responsable de vos données personnelles (responsable du traitement). Écrivez à {contact} pour toute question sur cette politique.",
            ]),
            ("En bref", [
                "Pas de publicité, et vos données ne sont jamais vendues.",
                "Les statistiques d'utilisation et les rapports de plantage restent désactivés tant que vous ne les activez pas, et vous pouvez les désactiver à tout moment dans Paramètres → Confidentialité.",
                "Vous pouvez supprimer votre compte et votre progression synchronisée depuis l'app à tout moment.",
            ]),
            ("Ce que nous traitons et pourquoi", [
                "Votre compte. Lorsque vous continuez en invité, Firebase Authentication crée un identifiant utilisateur anonyme. Si vous créez un compte, il enregistre aussi votre adresse e-mail et un mot de passe haché de façon sécurisée. Nous les utilisons pour vous connecter et conserver votre progression avec votre compte. Base légale : fournir le service que vous demandez (art. 6, paragraphe 1, point b du RGPD).",
                "Votre progression : les leçons terminées, votre meilleur score et la date. Elle est enregistrée sur votre appareil et, tant que vous êtes connecté, dans Cloud Firestore dans l'Union européenne (multirégion eur3) sous votre identifiant, pour qu'elle soit en sécurité et vous suive sur vos autres appareils. Base légale : art. 6, paragraphe 1, point b du RGPD.",
                "Vos paramètres (langue de l'app, thème, objectif quotidien, main, réduction des animations et vos choix de confidentialité) sont enregistrés uniquement sur votre appareil.",
                "Rapports de plantage, uniquement si vous les activez. Firebase Crashlytics reçoit des détails techniques lorsque l'app plante ou rencontre une erreur : la trace d'appels, le modèle de l'appareil, les versions du système et de l'app, et un identifiant d'installation. Base légale : votre consentement (art. 6, paragraphe 1, point a du RGPD). Les rapports sont conservés 90 jours.",
                "Statistiques d'utilisation, uniquement si vous les activez. Google Analytics for Firebase reçoit un petit ensemble d'événements (configuration initiale terminée, inscription ou connexion, leçon terminée avec son score), un identifiant d'instance de l'app, les versions de l'appareil et de l'app, et votre pays approximatif déduit de votre adresse IP. Aucun identifiant publicitaire n'est collecté et la personnalisation des annonces est désactivée. Base légale : votre consentement (art. 6, paragraphe 1, point a du RGPD). Les données sont conservées 2 mois.",
                "Les vidéos et images des signes sont servies par Firebase Hosting. Comme tout serveur web, il traite votre adresse IP pour vous envoyer les fichiers.",
            ]),
            ("Qui traite des données pour nous", [
                "Google Ireland Limited et Google LLC fournissent Firebase et traitent des données pour notre compte selon les conditions de traitement des données de Firebase. Certaines données peuvent être traitées aux États-Unis ; Google s'appuie sur le cadre de protection des données UE–États-Unis et les clauses contractuelles types de la Commission européenne.",
            ]),
            ("Durée de conservation", [
                "Votre compte et votre progression synchronisée : jusqu'à la suppression de votre compte. Rapports de plantage : 90 jours. Statistiques d'utilisation : 2 mois. Données sur votre appareil : jusqu'à la suppression de l'app ou de votre compte.",
            ]),
            ("Vos droits", [
                "Vous pouvez demander l'accès à vos données, leur rectification ou leur effacement, une copie dans un format portable, et vous pouvez limiter le traitement ou vous y opposer. Vous pouvez retirer votre consentement à tout moment dans Paramètres → Confidentialité, sans effet sur le traitement antérieur. Vous pouvez aussi saisir l'autorité de protection des données du pays de l'UE où vous vivez.",
            ]),
            ("Supprimer votre compte", [
                "Dans l'app, ouvrez Profil → Supprimer le compte. Votre compte et votre progression synchronisée sont supprimés immédiatement. Sans l'app, suivez les étapes sur {delete_url}.",
            ]),
            ("Enfants", [
                "Gestura ne s'adresse pas aux enfants de moins de 13 ans. Si vous pensez qu'un enfant nous a transmis des données personnelles, écrivez à {contact} et nous les supprimerons.",
            ]),
            ("Sécurité", [
                "Les données sont chiffrées en transit et au repos. Les règles de la base de données ne vous permettent de lire et de modifier que vos propres données.",
            ]),
            ("Modifications", [
                "Si cette politique change, nous mettons à jour cette page et sa date, et nous vous informons des changements importants dans l'app.",
            ]),
        ],
    },
    "de": {
        "title": "Datenschutzerklärung von Gestura",
        "updated": "Zuletzt aktualisiert: {date}",
        "sections": [
            ("Verantwortlicher", [
                "Gestura wird von {controller} entwickelt, der für deine personenbezogenen Daten verantwortlich ist (Verantwortlicher). Schreib an {contact}, wenn du Fragen zu dieser Erklärung hast.",
            ]),
            ("Kurz gesagt", [
                "Keine Werbung, und deine Daten werden niemals verkauft.",
                "Nutzungsstatistik und Absturzberichte bleiben aus, bis du sie einschaltest, und du kannst sie jederzeit unter Einstellungen → Datenschutz wieder ausschalten.",
                "Du kannst dein Konto und deinen synchronisierten Fortschritt jederzeit in der App löschen.",
            ]),
            ("Was wir verarbeiten und warum", [
                "Dein Konto. Wenn du als Gast fortfährst, erstellt Firebase Authentication eine anonyme Nutzer-ID. Wenn du ein Konto erstellst, werden außerdem deine E-Mail-Adresse und ein sicher gehashtes Passwort gespeichert. Wir nutzen sie, um dich anzumelden und deinen Fortschritt mit deinem Konto zu verbinden. Rechtsgrundlage: Erbringung des von dir gewünschten Dienstes (Art. 6 Abs. 1 lit. b DSGVO).",
                "Dein Lernfortschritt: welche Lektionen du abgeschlossen hast, dein bestes Ergebnis und wann. Er wird auf deinem Gerät gespeichert und, solange du angemeldet bist, in Cloud Firestore in der Europäischen Union (Multi-Region eur3) unter deiner Nutzer-ID, damit er sicher ist und dich auf deine anderen Geräte begleitet. Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO.",
                "Deine Einstellungen (App-Sprache, Design, Tagesziel, Hand, reduzierte Bewegung und deine Datenschutzentscheidungen) werden nur auf deinem Gerät gespeichert.",
                "Absturzberichte, nur wenn du sie einschaltest. Firebase Crashlytics erhält technische Details, wenn die App abstürzt oder auf einen Fehler stößt: den Stacktrace, das Gerätemodell, die Version von Betriebssystem und App sowie eine Installations-ID. Rechtsgrundlage: deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO). Berichte werden 90 Tage aufbewahrt.",
                "Nutzungsstatistik, nur wenn du sie einschaltest. Google Analytics for Firebase erhält wenige Ereignisse (Einrichtung abgeschlossen, registriert oder angemeldet, Lektion mit Ergebnis abgeschlossen), eine App-Instanz-ID, die Geräte- und App-Version sowie dein ungefähres Land, abgeleitet aus deiner IP-Adresse. Werbe-IDs werden nicht erfasst und personalisierte Werbung ist aus. Rechtsgrundlage: deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO). Die Daten werden 2 Monate aufbewahrt.",
                "Gebärdenvideos und -bilder werden über Firebase Hosting ausgeliefert. Wie jeder Webserver verarbeitet er deine IP-Adresse, um dir die Dateien zu senden.",
            ]),
            ("Wer Daten in unserem Auftrag verarbeitet", [
                "Google Ireland Limited und Google LLC stellen Firebase bereit und verarbeiten Daten in unserem Auftrag nach den Firebase-Bedingungen zur Datenverarbeitung. Einige Daten können in den USA verarbeitet werden; Google stützt sich auf das EU-US Data Privacy Framework und die Standardvertragsklauseln der Europäischen Kommission.",
            ]),
            ("Wie lange wir Daten speichern", [
                "Dein Konto und dein synchronisierter Fortschritt: bis du dein Konto löschst. Absturzberichte: 90 Tage. Nutzungsstatistik: 2 Monate. Daten auf deinem Gerät: bis du die App oder dein Konto löschst.",
            ]),
            ("Deine Rechte", [
                "Du kannst Auskunft über deine Daten, ihre Berichtigung oder Löschung und eine Kopie in einem übertragbaren Format verlangen sowie die Verarbeitung einschränken oder ihr widersprechen. Deine Einwilligung kannst du jederzeit unter Einstellungen → Datenschutz widerrufen; die Verarbeitung bis dahin bleibt davon unberührt. Außerdem kannst du dich bei der Datenschutzaufsichtsbehörde des EU-Landes beschweren, in dem du lebst.",
            ]),
            ("Dein Konto löschen", [
                "Öffne in der App Profil → Konto löschen. Dein Konto und dein synchronisierter Fortschritt werden sofort gelöscht. Ohne die App folge den Schritten auf {delete_url}.",
            ]),
            ("Kinder", [
                "Gestura richtet sich nicht an Kinder unter 13 Jahren. Wenn du glaubst, dass uns ein Kind personenbezogene Daten gegeben hat, schreib an {contact}, und wir löschen sie.",
            ]),
            ("Sicherheit", [
                "Daten werden bei der Übertragung und im Speicher verschlüsselt. Die Datenbankregeln erlauben dir nur, deine eigenen Daten zu lesen und zu ändern.",
            ]),
            ("Änderungen", [
                "Wenn sich diese Erklärung ändert, aktualisieren wir diese Seite und ihr Datum und informieren dich in der App über wichtige Änderungen.",
            ]),
        ],
    },
}

DELETION = {
    "en": {
        "title": "Delete your Gestura account",
        "steps": [
            "In the app: open Profile → Delete account. Your account and the learning progress synced with it are deleted right away.",
            "Without the app: email {contact} from the address of your account with the subject “Delete my Gestura account”. We delete the account and all its data within 30 days and confirm by email.",
            "What is deleted: your user ID, email address and password, and your synced progress. Crash reports and usage analytics, if you turned them on, are not linked to your account and expire after 90 days and 2 months.",
        ],
    },
    "ar": {
        "title": "حذف حسابك في Gestura",
        "steps": [
            "من التطبيق: افتح الملف الشخصي ← حذف الحساب. يُحذف حسابك وتقدّمك المتزامن معه فورًا.",
            "من دون التطبيق: راسل {contact} من بريد حسابك بعنوان «احذف حسابي في Gestura». نحذف الحساب وكل بياناته خلال 30 يومًا ونؤكد ذلك بالبريد.",
            "ما يُحذف: معرّف المستخدم والبريد الإلكتروني وكلمة المرور وتقدّمك المتزامن. أما تقارير الأعطال وإحصاءات الاستخدام، إن كنت شغّلتها، فغير مرتبطة بحسابك وتنتهي بعد 90 يومًا وشهرين.",
        ],
    },
    "ru": {
        "title": "Удаление аккаунта Gestura",
        "steps": [
            "В приложении: откройте «Профиль → Удалить аккаунт». Аккаунт и синхронизированный с ним прогресс удаляются сразу.",
            "Без приложения: напишите на {contact} с адреса вашего аккаунта с темой «Удалить мой аккаунт Gestura». Мы удалим аккаунт и все его данные в течение 30 дней и подтвердим по почте.",
            "Что удаляется: идентификатор пользователя, адрес электронной почты, пароль и синхронизированный прогресс. Отчёты о сбоях и статистика использования, если вы их включали, не связаны с аккаунтом и удаляются через 90 дней и 2 месяца.",
        ],
    },
    "es": {
        "title": "Eliminar tu cuenta de Gestura",
        "steps": [
            "En la app: abre Perfil → Eliminar cuenta. Tu cuenta y el progreso sincronizado con ella se eliminan al instante.",
            "Sin la app: escribe a {contact} desde la dirección de tu cuenta con el asunto «Eliminar mi cuenta de Gestura». Eliminamos la cuenta y todos sus datos en un plazo de 30 días y te lo confirmamos por correo.",
            "Qué se elimina: tu identificador de usuario, tu correo, tu contraseña y tu progreso sincronizado. Los informes de errores y las estadísticas de uso, si los activaste, no están vinculados a tu cuenta y caducan a los 90 días y a los 2 meses.",
        ],
    },
    "fr": {
        "title": "Supprimer votre compte Gestura",
        "steps": [
            "Dans l'app : ouvrez Profil → Supprimer le compte. Votre compte et la progression synchronisée sont supprimés immédiatement.",
            "Sans l'app : écrivez à {contact} depuis l'adresse de votre compte avec l'objet « Supprimer mon compte Gestura ». Nous supprimons le compte et toutes ses données sous 30 jours et vous le confirmons par e-mail.",
            "Ce qui est supprimé : votre identifiant, votre adresse e-mail, votre mot de passe et votre progression synchronisée. Les rapports de plantage et les statistiques d'utilisation, si vous les avez activés, ne sont pas liés à votre compte et expirent après 90 jours et 2 mois.",
        ],
    },
    "de": {
        "title": "Dein Gestura-Konto löschen",
        "steps": [
            "In der App: Öffne Profil → Konto löschen. Dein Konto und der damit synchronisierte Fortschritt werden sofort gelöscht.",
            "Ohne die App: Schreib von der Adresse deines Kontos an {contact} mit dem Betreff „Mein Gestura-Konto löschen“. Wir löschen das Konto und alle zugehörigen Daten innerhalb von 30 Tagen und bestätigen es per E-Mail.",
            "Was gelöscht wird: deine Nutzer-ID, E-Mail-Adresse, dein Passwort und dein synchronisierter Fortschritt. Absturzberichte und Nutzungsstatistik, falls du sie eingeschaltet hattest, sind nicht mit deinem Konto verknüpft und laufen nach 90 Tagen bzw. 2 Monaten ab.",
        ],
    },
}
