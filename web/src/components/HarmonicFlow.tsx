import { useEffect, useState, useMemo } from 'react'
import './HarmonicFlow.css'

interface HarmonicFlowProps {
    text: string
    onComplete?: () => void
    duration?: number
}

function HarmonicFlow({ text, onComplete, duration = 2000 }: HarmonicFlowProps) {
    const textLines = useMemo(() => {
        const maxChars = 45
        const rawLines = text.split('\n').filter(l => l.trim())
        const result: string[] = []

        for (const line of rawLines) {
            if (line.length <= maxChars) {
                result.push(line)
                continue
            }
            const words = line.split(/\s+/)
            let current = ''
            for (const word of words) {
                if (current.length + word.length + 1 > maxChars && current) {
                    result.push(current)
                    current = word
                } else {
                    current = current ? `${current} ${word}` : word
                }
            }
            if (current) result.push(current)
        }

        return result.length ? result : ['']
    }, [text])

    const maxLen = Math.max(...textLines.map(l => l.length))

    useEffect(() => {
        if (onComplete) {
            const timer = setTimeout(onComplete, duration)
            return () => clearTimeout(timer)
        }
    }, [onComplete, duration])

    return (
        <div className="harmonic-flow">
            {textLines.map((line, index) => (
                <HarmonicBar
                    key={index}
                    lineLength={line.length}
                    delay={index * 0.08}
                    maxLen={maxLen}
                />
            ))}
        </div>
    )
}

function HarmonicBar({ lineLength, delay, maxLen }: { lineLength: number, delay: number, maxLen: number }) {
    const denominator = Math.max(20, maxLen)
    const ratio = Math.min(1.0, Math.max(0.2, lineLength / denominator))

    const [animating, setAnimating] = useState(false)

    useEffect(() => {
        const timer = setTimeout(() => setAnimating(true), delay * 1000)
        return () => clearTimeout(timer)
    }, [delay])

    return (
        <div
            className={`harmonic-bar${animating ? ' animating' : ''}`}
            style={{ width: `${ratio * 100}%` }}
        />
    )
}

export default HarmonicFlow
