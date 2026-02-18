import { useState, useEffect, useCallback, useRef } from 'react'
import './BeyondDemos.css'
import HarmonicFlow from './HarmonicFlow'
import { useI18n, tr } from '../i18n'

type PresetPhase = 'idle' | 'selecting' | 'shortcut' | 'popup' | 'result'

export function PresetModeDemo() {
    const { lang, t } = useI18n()
    const [phase, setPhase] = useState<PresetPhase>('idle')
    const [selProgress, setSelProgress] = useState(0)
    const timerRef = useRef<number>(0)
    const rafRef = useRef<number>(0)

    const sourceText = tr(t.beyond.presetSourceText, lang)
    const resultText = tr(t.beyond.presetResultText, lang)
    const presetTag = tr(t.beyond.presetTag, lang)

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
        <div className="bd-demo-container bd-preset-container">
            <div className="bd-demo bd-preset">
                <div className="bd-window">
                    <div className="bd-win-bar">
                        <span className="bd-win-dot" />
                        <span className="bd-win-dot" />
                        <span className="bd-win-dot" />
                        <span className="bd-preset-tag">{presetTag}</span>
                    </div>
                    <div className="bd-win-body">
                        <p className="bd-doc-text">
                            {Array.from(sourceText).map((ch, i) => (
                                <span
                                    key={i}
                                    className={i < selChars ? 'bd-sel' : ''}
                                >{ch}</span>
                            ))}
                        </p>
                    </div>
                </div>

                <div className={`bd-keys${showKeys ? ' visible' : ''}`}>
                    <kbd className={`bd-key-cap${keysPressed ? ' pressed' : ''}`}>Cmd</kbd>
                    <span className="bd-key-plus">+</span>
                    <kbd className={`bd-key-cap${keysPressed ? ' pressed' : ''}`}>C</kbd>
                    <span className="bd-key-plus">+</span>
                    <kbd className={`bd-key-cap${keysPressed ? ' pressed' : ''}`}>C</kbd>
                </div>

                {(phase === 'popup' || phase === 'result') && (
                    <div className="bd-popup">
                        <div className="bd-popup-bar">
                            <span className="bd-popup-dot" />
                            <span className="bd-popup-dot" />
                            <span className="bd-popup-dot" />
                        </div>
                        <div className="bd-popup-panels">
                            <div className="bd-popup-panel">
                                <p className="bd-popup-text bd-popup-source">{sourceText}</p>
                            </div>
                            <div className="bd-popup-divider" />
                            <div className="bd-popup-panel">
                                {phase === 'popup' && (
                                    <div className="bd-popup-loading">
                                        <HarmonicFlow text={resultText} duration={1500} onComplete={onLoadingDone} />
                                    </div>
                                )}
                                {phase === 'result' && (
                                    <p className="bd-popup-text bd-popup-result">{resultText}</p>
                                )}
                            </div>
                        </div>
                        <div className="bd-popup-footer">
                            <span className="bd-yisi-btn">Yisi</span>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}

type CustomPhase = 'idle' | 'showPopup' | 'typeField1' | 'typeField2' | 'loading' | 'result'

export function CustomModeDemo() {
    const { lang, t } = useI18n()
    const [phase, setPhase] = useState<CustomPhase>('idle')
    const [typed1, setTyped1] = useState(0)
    const [typed2, setTyped2] = useState(0)
    const timerRef = useRef<number>(0)

    const field1 = tr(t.beyond.narrativeField1, lang)
    const field2 = tr(t.beyond.narrativeField2, lang)
    const prefix = tr(t.beyond.narrativePrefix, lang)
    const comma = tr(t.beyond.narrativeComma, lang)
    const middle = tr(t.beyond.narrativeMiddle, lang)
    const suffix = tr(t.beyond.narrativeSuffix, lang)
    const sourceText = tr(t.beyond.customSourceText, lang)
    const resultText = tr(t.beyond.customResultText, lang)

    useEffect(() => {
        setPhase('idle')
        setTyped1(0)
        setTyped2(0)
    }, [lang])

    useEffect(() => {
        switch (phase) {
            case 'idle':
                setTyped1(0)
                setTyped2(0)
                timerRef.current = window.setTimeout(() => setPhase('showPopup'), 1500)
                break
            case 'showPopup':
                timerRef.current = window.setTimeout(() => setPhase('typeField1'), 600)
                break
            case 'typeField1': {
                let count = 0
                const typeNext = () => {
                    count++
                    setTyped1(count)
                    if (count < field1.length) {
                        timerRef.current = window.setTimeout(typeNext, 60 + Math.random() * 40)
                    } else {
                        timerRef.current = window.setTimeout(() => setPhase('typeField2'), 400)
                    }
                }
                timerRef.current = window.setTimeout(typeNext, 200)
                break
            }
            case 'typeField2': {
                let count = 0
                const typeNext = () => {
                    count++
                    setTyped2(count)
                    if (count < field2.length) {
                        timerRef.current = window.setTimeout(typeNext, 40 + Math.random() * 30)
                    } else {
                        timerRef.current = window.setTimeout(() => setPhase('loading'), 500)
                    }
                }
                timerRef.current = window.setTimeout(typeNext, 200)
                break
            }
            case 'loading':
                break
            case 'result':
                timerRef.current = window.setTimeout(() => setPhase('idle'), 3000)
                break
        }
        return () => clearTimeout(timerRef.current)
    }, [phase, field1.length, field2.length])

    const onLoadingDone = useCallback(() => setPhase('result'), [])

    const showPopup = phase !== 'idle'
    const field1Text = phase === 'typeField1' ? field1.slice(0, typed1) : (phase === 'idle' || phase === 'showPopup') ? '' : field1
    const field2Text = phase === 'typeField2' ? field2.slice(0, typed2) : (phase === 'idle' || phase === 'showPopup' || phase === 'typeField1') ? '' : field2
    const showCursor1 = phase === 'typeField1'
    const showCursor2 = phase === 'typeField2'

    return (
        <div className="bd-demo-container bd-custom-container">
            <div className="bd-demo bd-custom">
                <div className="bd-window bd-custom-source-window">
                    <div className="bd-win-bar">
                        <span className="bd-win-dot" />
                        <span className="bd-win-dot" />
                        <span className="bd-win-dot" />
                    </div>
                    <div className="bd-win-body">
                        <p className="bd-doc-text bd-sel-all">{sourceText}</p>
                    </div>
                </div>

                {showPopup && (
                    <div className="bd-popup bd-custom-popup">
                        <div className="bd-popup-bar">
                            <span className="bd-popup-dot" />
                            <span className="bd-popup-dot" />
                            <span className="bd-popup-dot" />
                        </div>
                        <div className="bd-custom-narrative">
                            <div className="bd-narrative-line">
                                <span className="bd-narrative-text">{prefix} </span>
                                <span className="bd-narrative-input">
                                    {field1Text}
                                    {showCursor1 && <span className="bd-cursor" />}
                                    {!field1Text && !showCursor1 && <span className="bd-input-placeholder" />}
                                </span>
                                <span className="bd-narrative-text"> {comma}</span>
                            </div>
                            <div className="bd-narrative-line">
                                <span className="bd-narrative-text">{middle} </span>
                                <span className="bd-narrative-input">
                                    {field2Text}
                                    {showCursor2 && <span className="bd-cursor" />}
                                    {!field2Text && !showCursor2 && <span className="bd-input-placeholder" />}
                                </span>
                                <span className="bd-narrative-text"> {suffix}</span>
                            </div>
                        </div>
                        <div className="bd-popup-panels">
                            <div className="bd-popup-panel">
                                <p className="bd-popup-text bd-popup-source">{sourceText}</p>
                            </div>
                            <div className="bd-popup-divider" />
                            <div className="bd-popup-panel">
                                {phase === 'loading' && (
                                    <div className="bd-popup-loading">
                                        <HarmonicFlow text={resultText} duration={1500} onComplete={onLoadingDone} />
                                    </div>
                                )}
                                {phase === 'result' && (
                                    <p className="bd-popup-text bd-popup-result">{resultText}</p>
                                )}
                            </div>
                        </div>
                        <div className="bd-popup-footer">
                            <span className="bd-yisi-btn">Yisi</span>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}

type VisionPhase = 'idle' | 'shortcut' | 'capture' | 'popup' | 'result'

export function VisionDemo() {
    const { lang, t } = useI18n()
    const [phase, setPhase] = useState<VisionPhase>('idle')
    const [captureProgress, setCaptureProgress] = useState(0)
    const timerRef = useRef<number>(0)
    const rafRef = useRef<number>(0)

    const resultText = tr(t.beyond.visionResultText, lang)

    useEffect(() => {
        setPhase('idle')
        setCaptureProgress(0)
    }, [lang])

    useEffect(() => {
        switch (phase) {
            case 'idle':
                setCaptureProgress(0)
                timerRef.current = window.setTimeout(() => setPhase('shortcut'), 1500)
                break
            case 'shortcut':
                timerRef.current = window.setTimeout(() => setPhase('capture'), 700)
                break
            case 'capture': {
                const t0 = performance.now()
                const dur = 800
                const tick = (now: number) => {
                    const p = Math.min(1, (now - t0) / dur)
                    setCaptureProgress(p)
                    if (p < 1) {
                        rafRef.current = requestAnimationFrame(tick)
                    } else {
                        timerRef.current = window.setTimeout(() => setPhase('popup'), 400)
                    }
                }
                rafRef.current = requestAnimationFrame(tick)
                break
            }
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

    const showKeys = phase === 'shortcut'
    const showCapture = phase === 'capture' || phase === 'popup' || phase === 'result'

    return (
        <div className="bd-demo-container bd-vision-container">
            <div className="bd-demo bd-vision">
                <div className="bd-vision-screen">
                    <div className="bd-vision-mock">
                        <div className="bd-mock-toolbar">
                            <span className="bd-mock-block bd-mock-w1" />
                            <span className="bd-mock-block bd-mock-w2" />
                            <span className="bd-mock-block bd-mock-w3" />
                        </div>
                        <div className="bd-mock-content">
                            <span className="bd-mock-line bd-mock-l1" />
                            <span className="bd-mock-line bd-mock-l2" />
                            <span className="bd-mock-line bd-mock-l3" />
                            <div className="bd-mock-btn-row">
                                <span className="bd-mock-btn">Submit</span>
                                <span className="bd-mock-btn bd-mock-btn-ghost">Cancel</span>
                                <span className="bd-mock-btn bd-mock-btn-ghost">Settings</span>
                            </div>
                        </div>
                        {showCapture && (
                            <div
                                className="bd-capture-rect"
                                style={{
                                    width: `${captureProgress * 85}%`,
                                    height: `${captureProgress * 70}%`,
                                }}
                            />
                        )}
                    </div>
                </div>

                <div className={`bd-keys${showKeys ? ' visible' : ''}`}>
                    <kbd className={`bd-key-cap${showKeys ? ' pressed' : ''}`}>Cmd</kbd>
                    <span className="bd-key-plus">+</span>
                    <kbd className={`bd-key-cap${showKeys ? ' pressed' : ''}`}>Shift</kbd>
                    <span className="bd-key-plus">+</span>
                    <kbd className={`bd-key-cap${showKeys ? ' pressed' : ''}`}>X</kbd>
                </div>

                {(phase === 'popup' || phase === 'result') && (
                    <div className="bd-popup">
                        <div className="bd-popup-bar">
                            <span className="bd-popup-dot" />
                            <span className="bd-popup-dot" />
                            <span className="bd-popup-dot" />
                        </div>
                        <div className="bd-popup-panels">
                            <div className="bd-popup-panel bd-vision-img-panel">
                                <div className="bd-vision-thumb" />
                            </div>
                            <div className="bd-popup-divider" />
                            <div className="bd-popup-panel">
                                {phase === 'popup' && (
                                    <div className="bd-popup-loading">
                                        <HarmonicFlow text={resultText} duration={1500} onComplete={onLoadingDone} />
                                    </div>
                                )}
                                {phase === 'result' && (
                                    <p className="bd-popup-text bd-popup-result bd-vision-result">{resultText}</p>
                                )}
                            </div>
                        </div>
                        <div className="bd-popup-footer">
                            <span className="bd-yisi-btn">Yisi</span>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}
