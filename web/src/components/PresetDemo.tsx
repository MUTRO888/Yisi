import { useState, useEffect, useCallback, useRef } from 'react'
import './PresetDemo.css'
import HarmonicFlow from './HarmonicFlow'
import { useI18n, tr } from '../i18n'

type PresetPhase = 'idle' | 'selecting' | 'shortcut' | 'popup' | 'result'

function PresetDemo() {
    const { lang, t } = useI18n()
    const [phase, setPhase] = useState<PresetPhase>('idle')
    const [selProgress, setSelProgress] = useState(0)
    const timerRef = useRef<number>(0)
    const rafRef = useRef<number>(0)

    const sourceText = tr(t.beyond.demoSourceText, lang)
    const targetText = tr(t.beyond.demoTargetText, lang)
    const sourceLang = tr(t.beyond.popupSourceLang, lang)
    const targetLang = tr(t.beyond.popupTargetLang, lang)

    useEffect(() => {
        setPhase('idle')
        setSelProgress(0)
    }, [lang])

    useEffect(() => {
        switch (phase) {
            case 'idle':
                setSelProgress(0)
                timerRef.current = window.setTimeout(() => setPhase('selecting'), 1500)
                break
            case 'selecting': {
                const t0 = performance.now()
                const dur = 600
                const tick = (now: number) => {
                    const p = Math.min(1, (now - t0) / dur)
                    setSelProgress(p)
                    if (p < 1) {
                        rafRef.current = requestAnimationFrame(tick)
                    } else {
                        timerRef.current = window.setTimeout(() => setPhase('shortcut'), 400)
                    }
                }
                rafRef.current = requestAnimationFrame(tick)
                break
            }
            case 'shortcut':
                timerRef.current = window.setTimeout(() => setPhase('popup'), 800)
                break
            case 'popup':
                break
            case 'result':
                timerRef.current = window.setTimeout(() => setPhase('idle'), 3000)
                break
        }

        return () => {
            clearTimeout(timerRef.current)
            cancelAnimationFrame(rafRef.current)
        }
    }, [phase])

    const onLoadingDone = useCallback(() => setPhase('result'), [])

    const selChars = phase === 'selecting'
        ? Math.floor(selProgress * sourceText.length)
        : (phase === 'idle' ? 0 : sourceText.length)

    const showKeys = phase === 'shortcut' || phase === 'popup' || phase === 'result'
    const keysPressed = phase === 'shortcut'

    return (
        <div className="preset-demo">
            <div className="pd-document">
                <div className="pd-doc-bar">
                    <span className="pd-doc-dot" />
                    <span className="pd-doc-dot" />
                    <span className="pd-doc-dot" />
                </div>
                <div className="pd-doc-body">
                    <p className="pd-doc-text">
                        {Array.from(sourceText).map((ch, i) => (
                            <span
                                key={i}
                                className={i < selChars ? 'pd-sel' : ''}
                            >{ch}</span>
                        ))}
                    </p>
                </div>
            </div>

            <div className={`pd-keys${showKeys ? ' visible' : ''}`}>
                <kbd className={`pd-key-cap${keysPressed ? ' pressed' : ''}`}>Cmd</kbd>
                <span className="pd-key-plus">+</span>
                <kbd className={`pd-key-cap${keysPressed ? ' pressed' : ''}`}>C</kbd>
                <span className="pd-key-plus">+</span>
                <kbd className={`pd-key-cap${keysPressed ? ' pressed' : ''}`}>C</kbd>
            </div>

            {(phase === 'popup' || phase === 'result') && (
                <div className="pd-popup">
                    <div className="pd-popup-bar">
                        <span className="pd-popup-dot" />
                        <span className="pd-popup-dot" />
                        <span className="pd-popup-dot" />
                    </div>
                    <div className="pd-lang-bar">
                        <span className="pd-lang-label">{sourceLang}</span>
                        <span className="pd-lang-arrow" aria-hidden="true" />
                        <span className="pd-lang-label">{targetLang}</span>
                    </div>
                    <div className="pd-popup-panels">
                        <div className="pd-popup-panel">
                            <p className="pd-popup-text pd-popup-source">
                                {sourceText.slice(0, 60)}{sourceText.length > 60 ? '...' : ''}
                            </p>
                        </div>
                        <div className="pd-popup-divider" />
                        <div className="pd-popup-panel">
                            {phase === 'popup' && (
                                <div className="pd-popup-loading">
                                    <HarmonicFlow
                                        text={targetText}
                                        duration={1500}
                                        onComplete={onLoadingDone}
                                    />
                                </div>
                            )}
                            {phase === 'result' && (
                                <p className="pd-popup-text pd-popup-result">
                                    {targetText.slice(0, 60)}{targetText.length > 60 ? '...' : ''}
                                </p>
                            )}
                        </div>
                    </div>
                    <div className="pd-popup-footer">
                        <span className="pd-yisi-btn">Yisi</span>
                    </div>
                </div>
            )}
        </div>
    )
}

export default PresetDemo
