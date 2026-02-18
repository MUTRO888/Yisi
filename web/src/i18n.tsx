import { createContext, useContext, useState, useCallback, type ReactNode } from 'react'

type Lang = 'en' | 'zh'

const translations = {
    header: {
        features: { en: 'Features', zh: '功能' },
        beyond: { en: 'Beyond', zh: '超越' },
        whyYisi: { en: 'Why Yisi', zh: '为什么' },
    },
    hero: {
        download: { en: 'Download for macOS', zh: '下载 macOS 版' },
        explore: { en: 'Explore features', zh: '探索功能' },
    },
    showcase: {
        heading: {
            en: 'At first, you just wanted a good translator. Then you realized \u2014 any information can take the form you need.',
            zh: '最初，你只想要一个好用的翻译工具。然后发现，任何信息都可以以你需要的形式呈现。',
        },
        sub: {
            en: 'Yisi is a semantic transformation tool built for macOS. Starting from translation, silent and elegant.',
            zh: 'Yisi 是为 macOS 打造的智能语义转换工具。从翻译出发，无声，优雅。',
        },
        placeholder: { en: 'App Preview', zh: '应用预览' },
        demoSourceLang: { en: 'English', zh: '中文' },
        demoTargetLang: { en: 'Chinese', zh: 'English' },
        demoSourceText: {
            en: 'The autumn moon shines quietly on the mountain, the pine wind blows through the evening stillness.',
            zh: '秋月照高山，松风吹晚静。',
        },
        demoTargetText: {
            en: '秋月照高山，松风吹晚静。',
            zh: 'The autumn moon shines quietly on the mountain, the pine wind blows through the evening stillness.',
        },
    },
    features: {
        heading: { en: 'Translation, done right', zh: '翻译，做到极致' },
        items: [
            {
                label: { en: 'Quality', zh: '品质' },
                title: { en: 'Natural output', zh: '地道的译文' },
                description: {
                    en: 'Built-in carefully refined translation prompts. Not mechanical word-for-word conversion, but truly readable, natural language output.',
                    zh: '内置经过反复打磨的翻译 Prompt，不是字对字的机械转换，而是真正可读、自然的语言输出。',
                },
            },
            {
                label: { en: 'Learning', zh: '学习' },
                title: { en: 'Learns your style', zh: '越用越懂你' },
                description: {
                    en: 'When you correct a term or adjust an expression, Yisi remembers it as a rule, automatically applying it in future translations. You never need to explain twice.',
                    zh: '当你纠正了一个术语，或者调整了一种表达方式，Yisi 会把这个偏好记住，变成规则，在之后的翻译里自动应用。你不需要每次重新说明。',
                },
            },
            {
                label: { en: 'Offline', zh: '离线' },
                title: { en: 'Works without internet', zh: '断网也能用' },
                description: {
                    en: 'Integrated with macOS native System Translation. No internet needed, no API key required. All processing happens locally \u2014 your data never leaves your device.',
                    zh: '集成 macOS 原生 System Translation，无需联网，无需 API Key。数据完全在本地处理，不经过任何服务器，隐私得到最彻底的保护。',
                },
            },
        ],
    },
    beyond: {
        heading: { en: 'Then, beyond translation', zh: '然后，超越翻译' },
        sub: {
            en: 'Translation is language to language. But the transformations information needs go far beyond that.',
            zh: '翻译是语言到语言的转换。但信息需要的转换，远不止于此。',
        },
        demoSourceText: {
            en: 'The committee has unanimously decided to postpone the implementation of the proposed regulatory framework pending further review.',
            zh: '委员会一致决定推迟实施拟议的监管框架，等待进一步审查。',
        },
        demoTargetText: {
            en: '委员会一致决定推迟实施拟议的监管框架，等待进一步审查。',
            zh: 'The committee has unanimously decided to postpone the implementation of the proposed regulatory framework pending further review.',
        },
        narrativePrefix: {
            en: 'This is',
            zh: '这是',
        },
        narrativeField1: {
            en: 'Ancient Poetry',
            zh: '古诗词',
        },
        narrativeComma: {
            en: ',',
            zh: '，',
        },
        narrativeMiddle: {
            en: 'please',
            zh: '请',
        },
        narrativeField2: {
            en: 'translate to modern English',
            zh: '翻译为现代白话文',
        },
        narrativeSuffix: {
            en: '.',
            zh: '。',
        },
        presetTag: {
            en: 'Prompt Refiner',
            zh: '指令精炼',
        },
        presetSourceText: {
            en: 'make this email sound more professional and less casual',
            zh: '帮我把这封邮件改得更专业一点，别太随意',
        },
        presetResultText: {
            en: 'Rewrite the email in formal business English. Maintain the core message. Use complete sentences, proper salutations, and professional closings.',
            zh: '将邮件改写为正式商务中文。保留核心信息。使用完整句式、规范称谓和专业落款。去除口语化表达。',
        },
        popupSourceLang: {
            en: 'Auto Detect',
            zh: '自动检测',
        },
        popupTargetLang: {
            en: 'Chinese',
            zh: '简体中文',
        },
        customSourceText: {
            en: 'Waters hush on jagged rocks, cold light rests on pine',
            zh: '泉声咽危石，日色冷青松',
        },
        customResultText: {
            en: 'Spring water gurgles softly over steep rocks,\nsunlight casts a cold glow on the green pines.',
            zh: '泉水在陡峭的岩石上轻轻流淌，\n日光给苍翠的松林披上清冷的光。',
        },
        visionImageAlt: {
            en: 'Screenshot region',
            zh: '截图区域',
        },
        visionResultText: {
            en: 'Detected: UI mockup with 3 text labels.\nExtracted: "Submit", "Cancel", "Settings"',
            zh: '检测到：含3个文字标签的UI设计稿。\n提取文字："提交"、"取消"、"设置"',
        },
        items: [
            {
                title: { en: 'Preset Mode', zh: '预设模式' },
                description: {
                    en: 'Define your scenario once: what the input is, and what output you want. From then on, select and trigger \u2014 no describing, no chatting. Presets are the embodiment of your thinking habits.',
                    zh: '提前定义好你的工作场景：这段输入是什么，你想要什么样的输出。此后选中即触发，触发即完成。预设是你思维习惯的具象化，是你工作方式的延伸。',
                },
            },
            {
                title: { en: 'Custom Mode', zh: '即时模式' },
                description: {
                    en: 'For one-off needs, no setup required. Two fields on trigger: what is this, and what should be done. Same logic as presets, just defined in the moment.',
                    zh: '当需求是一次性的，不需要提前配置。触发时直接呈现两个填空：这是什么，请做什么。与预设逻辑完全相同，区别只在于随用随填。',
                },
            },
            {
                title: { en: 'Vision Input', zh: '视觉也是输入' },
                description: {
                    en: 'When your question lives in an image \u2014 a design mockup, a data chart, an error screenshot \u2014 select any screen region. Text and images are both information, both transformable.',
                    zh: '当你的问题藏在一张图里——一份设计稿，一个数据图表，一个报错截图——框选屏幕上的任意区域。文字和图像，都是信息，都可以被转换。',
                },
            },
        ],
    },
    whyYisi: {
        heading: { en: 'Yisi has no dialog box', zh: 'Yisi 没有对话框' },
        sub: {
            en: 'Not \u201Cselect \u2192 open chat \u2192 describe \u2192 wait for reply\u201D, but \u201Cselect \u2192 present\u201D. You\u2019re not conversing with AI \u2014 you\u2019re doing what you were already doing, and AI quietly completes the transformation, then disappears.',
            zh: '不是「选中内容 \u2192 打开对话 \u2192 描述需求 \u2192 等待回复」，而是「选中 \u2192 呈现」。你不是在和 AI 交流——你只是在做你本来要做的事，AI 悄悄完成了那个转换，然后消失了。',
        },
        items: [
            {
                title: { en: 'No conversation needed', zh: '无需对话' },
                description: {
                    en: 'No chat history, no follow-up prompts, no AI persona. Left side: what you selected. Right side: its new form. Close the window, back where you were.',
                    zh: '没有对话历史，没有追问的入口，没有 AI 的名字和头像。左边是你选中的内容，右边是它的新形态。窗口关掉，一切如常。',
                },
            },
            {
                title: { en: 'Intent, pre-written', zh: '意图，提前固化' },
                description: {
                    en: 'Preset Mode takes this to the extreme. Your intent is already written into the preset. Select to trigger, trigger to complete. AI is a silent part of your workflow, not a conversation partner you visit.',
                    zh: '预设模式把这个逻辑推到了极致。你的意图早已写进了预设，选中即触发，触发即完成。AI 是你工作流里无声的一环，不是你去拜访的对话伙伴。',
                },
            },
            {
                title: { en: 'A tool, not an assistant', zh: '工具，不是助手' },
                description: {
                    en: 'When you just need to transform what\u2019s in front of you into another form, you don\u2019t need a conversation. You need a tool that silently completes the transformation.',
                    zh: '当你只是想把眼前这段内容变成另一种形式，你不需要建立一段对话关系。你需要的，是一个无声完成转换的工具。',
                },
            },
        ],
    },
    principles: {
        heading: { en: 'Free, open source, private', zh: '免费、开源、隐私' },
        items: [
            {
                title: { en: 'Completely free', zh: '完全免费' },
                description: {
                    en: 'No subscription, no membership, no hidden charges. Download and use immediately, no registration required.',
                    zh: '没有订阅，没有会员，没有任何隐藏收费。无需注册，下载即用。',
                },
            },
            {
                title: { en: 'Fully open source', zh: '代码完全开源' },
                description: {
                    en: 'Every line of code is public. Transparency is not a promise \u2014 it\u2019s a verifiable fact.',
                    zh: '每一行代码都是公开的。透明不是一种承诺——而是一个可验证的事实。',
                },
            },
            {
                title: { en: 'Privacy by architecture', zh: '架构级隐私' },
                description: {
                    en: 'In system translation mode, all processing is local \u2014 no servers, no data leaving your device. In AI mode, your API key goes directly to your chosen provider. Yisi never touches your content.',
                    zh: '使用系统翻译模式时，所有处理在本地完成，没有数据离开你的电脑。使用 AI 模式时，API Key 是你自己的，请求直接发往你选择的服务商，Yisi 本身不经手任何内容。',
                },
            },
        ],
    },
    downloadCTA: {
        heading: { en: 'Get started in three steps', zh: '三步开始' },
        steps: [
            {
                label: { en: 'Select', zh: '选中' },
                description: {
                    en: 'Select text in any app, or press the screenshot shortcut to capture a screen region.',
                    zh: '在任何应用里选中文字，或按截图快捷键框选屏幕。',
                },
            },
            {
                label: { en: 'Trigger', zh: '触发' },
                description: {
                    en: 'Cmd+C+C for text, Cmd+Shift+X for screenshots.',
                    zh: 'Cmd+C+C（文本），Cmd+Shift+X（截图）。',
                },
            },
            {
                label: { en: 'Present', zh: '呈现' },
                description: {
                    en: 'Result appears instantly. Close to return.',
                    zh: '结果在弹窗中直接显示，关闭即返回。',
                },
            },
        ],
        button: { en: 'Download for macOS', zh: '下载 macOS 版' },
        requires: { en: 'Requires macOS 13 or later', zh: '需要 macOS 13 或更高版本' },
        source: { en: 'View source on GitHub', zh: '在 GitHub 上查看源码' },
    },
    footer: {
        tagline: {
            en: 'AI as a silent part of your workflow',
            zh: 'AI 是你工作流里无声的一环',
        },
        product: { en: 'Product', zh: '产品' },
        resources: { en: 'Resources', zh: '资源' },
        features: { en: 'Features', zh: '功能' },
        beyond: { en: 'Beyond translation', zh: '超越翻译' },
        whyYisi: { en: 'Why Yisi', zh: '为什么是 Yisi' },
        releases: { en: 'Releases', zh: '版本发布' },
        issues: { en: 'Issues', zh: '问题反馈' },
        license: { en: 'Released under the GNU GPLv3 License', zh: '基于 GNU GPLv3 许可证发布' },
    },
} as const

type Translations = typeof translations

interface I18nContextValue {
    lang: Lang
    toggle: () => void
    t: Translations
}

const I18nContext = createContext<I18nContextValue | null>(null)

export function I18nProvider({ children }: { children: ReactNode }) {
    const [lang, setLang] = useState<Lang>('zh')
    const toggle = useCallback(() => setLang(l => (l === 'en' ? 'zh' : 'en')), [])

    return (
        <I18nContext.Provider value={{ lang, toggle, t: translations }}>
            {children}
        </I18nContext.Provider>
    )
}

export function useI18n() {
    const ctx = useContext(I18nContext)
    if (!ctx) throw new Error('useI18n must be used within I18nProvider')
    return ctx
}

export function tr(entry: { en: string; zh: string }, lang: Lang): string {
    return entry[lang]
}
