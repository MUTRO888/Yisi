import { createContext, useContext, useState, useCallback, type ReactNode } from 'react'

type Lang = 'en' | 'zh'

const translations = {
    header: {
        features: { en: 'Features', zh: '功能' },
        workflow: { en: 'How it works', zh: '工作流程' },
        demo: { en: 'Demo', zh: '演示' },
    },
    hero: {
        download: { en: 'Download for macOS', zh: '下载 macOS 版' },
        explore: { en: 'Explore features', zh: '探索功能' },
    },
    showcase: {
        heading: { en: 'Translation, reimagined', zh: '翻译，重新定义' },
        sub: {
            en: 'A native macOS experience that understands context, respects privacy, and delivers clarity.',
            zh: '原生 macOS 体验，理解语境，尊重隐私，呈现清晰译文。',
        },
        placeholder: { en: 'App Preview', zh: '应用预览' },
    },
    features: {
        heading: { en: 'Designed for clarity', zh: '为清晰而设计' },
        items: [
            {
                label: { en: 'Privacy', zh: '隐私' },
                title: { en: 'On-Device Translation', zh: '端侧翻译' },
                description: {
                    en: 'All processing happens locally. Your data never leaves your Mac. No servers, no tracking, no compromises.',
                    zh: '所有处理均在本地完成。数据永远不会离开你的 Mac。无服务器、无追踪、无妥协。',
                },
            },
            {
                label: { en: 'Vision', zh: '视觉' },
                title: { en: 'OCR Capture', zh: 'OCR 截取' },
                description: {
                    en: 'Select any region of your screen to recognize and translate text instantly. Works with images, PDFs, and any application.',
                    zh: '选取屏幕任意区域，即时识别并翻译文字。支持图片、PDF 及任何应用。',
                },
            },
            {
                label: { en: 'Intelligence', zh: '智能' },
                title: { en: 'AI Optimization', zh: 'AI 优化' },
                description: {
                    en: 'Optional AI-powered refinement for more natural, context-aware translations that preserve meaning and tone.',
                    zh: '可选的 AI 润色功能，提供更自然、更有语境感的翻译，保留原文语义与语气。',
                },
            },
        ],
    },
    workflow: {
        heading: { en: 'Three steps to clarity', zh: '三步达意' },
        steps: [
            {
                title: { en: 'Capture', zh: '捕获' },
                description: {
                    en: 'Select any text on screen with a simple shortcut, or paste directly into the translation panel.',
                    zh: '通过快捷键选取屏幕上的任意文字，或直接粘贴至翻译面板。',
                },
            },
            {
                title: { en: 'Translate', zh: '翻译' },
                description: {
                    en: 'On-device engines process your text instantly. No network required, no data transmitted.',
                    zh: '端侧引擎即时处理文本，无需网络，不传输任何数据。',
                },
            },
            {
                title: { en: 'Refine', zh: '润色' },
                description: {
                    en: 'Optionally enhance results with AI optimization for nuance, tone, and context awareness.',
                    zh: '可选 AI 优化，提升翻译的细腻度、语气和语境理解。',
                },
            },
        ],
    },
    appDemo: {
        heading: { en: 'See it in action', zh: '实际体验' },
        sub: {
            en: 'Yisi integrates into your macOS workflow seamlessly.',
            zh: 'Yisi 无缝融入你的 macOS 工作流。',
        },
        placeholder: { en: 'Preview', zh: '预览' },
        demos: [
            {
                title: { en: 'Screen Capture', zh: '屏幕截取' },
                description: {
                    en: 'Select any region to translate text from images, PDFs, or applications.',
                    zh: '选取任意区域，翻译图片、PDF 或应用中的文字。',
                },
            },
            {
                title: { en: 'Quick Translate', zh: '快速翻译' },
                description: {
                    en: 'A floating panel for instant translation, accessible from any app.',
                    zh: '悬浮面板即时翻译，可在任何应用中调用。',
                },
            },
            {
                title: { en: 'Context Menu', zh: '右键菜单' },
                description: {
                    en: 'Right-click any selected text to translate without switching windows.',
                    zh: '右键选中文字即可翻译，无需切换窗口。',
                },
            },
        ],
    },
    principles: {
        heading: { en: 'Built on principles', zh: '以原则筑基' },
        items: [
            {
                title: { en: 'Privacy by design', zh: '隐私至上' },
                description: {
                    en: 'Translation happens entirely on your device. No servers, no tracking, no compromises. Your words stay yours.',
                    zh: '翻译完全在你的设备上完成。无服务器、无追踪、无妥协。你的文字只属于你。',
                },
            },
            {
                title: { en: 'Native craftsmanship', zh: '原生匠心' },
                description: {
                    en: 'Built exclusively for macOS with SwiftUI. Every interaction feels natural, fast, and at home on your Mac.',
                    zh: '专为 macOS 打造，采用 SwiftUI 开发。每一次交互都自然流畅，浑然天成。',
                },
            },
            {
                title: { en: 'Intelligent refinement', zh: '智能润色' },
                description: {
                    en: 'Context-aware AI enhancement is optional, never required. The best translation respects the original meaning.',
                    zh: '语境感知的 AI 增强为可选项，从不强制。最好的翻译始终尊重原意。',
                },
            },
        ],
    },
    downloadCTA: {
        heading: { en: 'Ready to translate differently?', zh: '准备好不一样的翻译体验了吗？' },
        sub: { en: 'Free, open source, and built for macOS.', zh: '免费、开源，专为 macOS 打造。' },
        button: { en: 'Download for macOS', zh: '下载 macOS 版' },
        requires: { en: 'Requires macOS 13 or later', zh: '需要 macOS 13 或更高版本' },
        source: { en: 'View source on GitHub', zh: '在 GitHub 上查看源码' },
    },
    footer: {
        tagline: { en: 'Privacy-first translation for macOS', zh: '隐私优先的 macOS 翻译工具' },
        product: { en: 'Product', zh: '产品' },
        resources: { en: 'Resources', zh: '资源' },
        features: { en: 'Features', zh: '功能' },
        workflow: { en: 'How it works', zh: '工作流程' },
        demo: { en: 'Demo', zh: '演示' },
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
    const [lang, setLang] = useState<Lang>('en')
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
