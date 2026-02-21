import { useState, useEffect, useCallback, useRef } from 'react'
import './Hero.css'
import HarmonicFlow from './HarmonicFlow'
import { useI18n, tr } from '../i18n'

type Phase = 'en' | 'en-sel' | 'en-flow' | 'cn' | 'cn-sel' | 'cn-flow'

const EN = 'Waters hush on jagged rocks, cold light rests on pine'
const CN = '泉声咽危石，日色冷青松'

function easeInOutCubic(t: number) {
    return t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2
}

function Hero() {
    const { lang, t } = useI18n()
    const [phase, setPhase] = useState<Phase>('en')
    const [selProg, setSelProg] = useState(0)
    const rafRef = useRef(0)

    useEffect(() => {
        let timer: number

        const runSel = (dur: number, next: Phase) => {
            const t0 = performance.now()
            const tick = (now: number) => {
                const p = Math.min(1, (now - t0) / dur)
                setSelProg(easeInOutCubic(p))
                if (p < 1) {
                    rafRef.current = requestAnimationFrame(tick)
                } else {
                    timer = window.setTimeout(() => setPhase(next), 350)
                }
            }
            rafRef.current = requestAnimationFrame(tick)
        }

        switch (phase) {
            case 'en':
                setSelProg(0)
                timer = window.setTimeout(() => setPhase('en-sel'), 2000)
                break
            case 'en-sel':
                runSel(700, 'en-flow')
                break
            case 'cn':
                setSelProg(0)
                timer = window.setTimeout(() => setPhase('cn-sel'), 2000)
                break
            case 'cn-sel':
                runSel(500, 'cn-flow')
                break
        }

        return () => {
            clearTimeout(timer)
            cancelAnimationFrame(rafRef.current)
        }
    }, [phase])

    const onEnFlowDone = useCallback(() => setPhase('cn'), [])
    const onCnFlowDone = useCallback(() => setPhase('en'), [])

    const enVisible = phase === 'en' || phase === 'en-sel'
    const cnVisible = phase === 'cn' || phase === 'cn-sel'
    const flowVisible = phase === 'en-flow' || phase === 'cn-flow'

    const enSel = phase === 'en-sel' ? Math.floor(selProg * EN.length) : 0
    const cnSel = phase === 'cn-sel' ? Math.floor(selProg * CN.length) : 0

    return (
        <section className="hero">
            <div className="hero-stage">
                <div className={`hero-layer${enVisible ? ' active' : ''}`}>
                    <h1 className="hero-headline hero-en">
                        {Array.from(EN).map((ch, i) => (
                            <span
                                key={i}
                                className={`hc${i < enSel ? ' sel' : ''}`}
                            >{ch}</span>
                        ))}
                    </h1>
                </div>

                <div className={`hero-layer${flowVisible ? ' active' : ''}`}>
                    {phase === 'en-flow' && (
                        <HarmonicFlow text={EN} duration={1000} onComplete={onEnFlowDone} />
                    )}
                    {phase === 'cn-flow' && (
                        <HarmonicFlow text={EN} duration={1000} onComplete={onCnFlowDone} />
                    )}
                </div>

                <div className={`hero-layer${cnVisible ? ' active' : ''}`}>
                    <h1 className="hero-headline hero-cn">
                        {Array.from(CN).map((ch, i) => (
                            <span
                                key={i}
                                className={`hc${i < cnSel ? ' sel' : ''}`}
                            >{ch}</span>
                        ))}
                    </h1>
                </div>
            </div>

            <div className="hero-bottom">
                <div className="hero-tagline">
                    <p className="hero-tagline-heading">{tr(t.showcase.heading, lang)}</p>
                    <p className="hero-tagline-sub">{tr(t.showcase.sub, lang)}</p>
                </div>
                <div className="hero-actions">
                    <a
                        href="https://github.com/MUTRO888/Yisi/releases"
                        className="btn-primary"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        {tr(t.hero.download, lang)}
                    </a>
                    <a href="#features" className="btn-ghost">
                        {tr(t.hero.explore, lang)}
                    </a>
                </div>
            </div>

            <div className="hero-scroll-hint" />
        </section>
    )
}

export default Hero
