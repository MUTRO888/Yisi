import { useMemo, type ElementType } from 'react'

interface TextRevealProps {
    text: string
    isVisible: boolean
    tag?: ElementType
    className?: string
    delayBase?: number
}

const CJK_RANGE = /[\u4e00-\u9fff\u3400-\u4dbf\u3000-\u303f\uff00-\uffef]/

function TextReveal({
    text,
    isVisible,
    tag: Tag = 'h2',
    className = '',
    delayBase = 40,
}: TextRevealProps) {
    const isCJK = useMemo(() => CJK_RANGE.test(text), [text])

    if (isCJK) {
        const chars = [...text]
        return (
            <Tag className={`text-reveal-wrap ${className}`}>
                {chars.map((char, i) => (
                    <span
                        key={i}
                        className={`text-reveal-word${isVisible ? ' text-reveal-visible' : ''}`}
                        style={{ transitionDelay: `${i * delayBase}ms` }}
                    >
                        {char}
                    </span>
                ))}
            </Tag>
        )
    }

    const words = text.split(/\s+/)

    return (
        <Tag className={`text-reveal-wrap ${className}`}>
            {words.map((word, i) => (
                <span
                    key={i}
                    className={`text-reveal-word${isVisible ? ' text-reveal-visible' : ''}`}
                    style={{ transitionDelay: `${i * delayBase}ms` }}
                >
                    {word}
                    {i < words.length - 1 ? '\u00A0' : ''}
                </span>
            ))}
        </Tag>
    )
}

export default TextReveal
