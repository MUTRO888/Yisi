import { useEffect, useState } from 'react'
import './HarmonicFlow.css'

interface HarmonicFlowProps {
    text: string
    onComplete?: () => void
    duration?: number
}

function HarmonicFlow({ text, onComplete, duration = 2000 }: HarmonicFlowProps) {
    // Generate visual lines similar to the Swift implementation
    const textLines = text.split('\n').filter(line => line.trim().length > 0)

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
                    delay={index * 0.1}
                    maxLen={Math.max(...textLines.map(l => l.length))}
                />
            ))}
        </div>
    )
}

function HarmonicBar({ lineLength, delay, maxLen }: { lineLength: number, delay: number, maxLen: number }) {
    // Calculate width ratio basically same as Swift logic
    // Normalizing against max length, clamping between 0.2 and 1.0
    const denominator = Math.max(20, maxLen)
    const ratio = Math.min(1.0, Math.max(0.2, lineLength / denominator))

    const [animationStarted, setAnimationStarted] = useState(false)

    useEffect(() => {
        const timer = setTimeout(() => {
            setAnimationStarted(true)
        }, delay * 1000)
        return () => clearTimeout(timer)
    }, [delay])

    return (
        <div
            className={`harmonic-bar ${animationStarted ? 'animating' : ''}`}
            style={{
                width: `${ratio * 100}%`,
                animationDelay: `${delay}s`
            }}
        />
    )
}

export default HarmonicFlow
