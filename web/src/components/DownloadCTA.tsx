import './DownloadCTA.css'
import { useI18n, tr } from '../i18n'
import { useScrollReveal } from '../hooks/useScrollReveal'
import TextReveal from './TextReveal'
import PresetDemo from './PresetDemo'

function DownloadCTA() {
    const { lang, t } = useI18n()
    const { ref, isVisible } = useScrollReveal()

    return (
        <section
            className="download-cta section"
            ref={ref as React.RefObject<HTMLElement>}
        >
            <div className="download-cta-inner container">
                <TextReveal
                    text={tr(t.downloadCTA.heading, lang)}
                    isVisible={isVisible}
                    className="download-cta-heading"
                />
                <div className={`download-cta-steps reveal-stagger${isVisible ? ' visible' : ''}`}>
                    {t.downloadCTA.steps.map((step, i) => (
                        <div
                            key={step.label.en}
                            className="cta-step reveal-child"
                            style={{ '--reveal-index': i } as React.CSSProperties}
                        >
                            <span className="cta-step-number">
                                {String(i + 1).padStart(2, '0')}
                            </span>
                            <div className="cta-step-content">
                                <span className="cta-step-label">{tr(step.label, lang)}</span>
                                <p className="cta-step-desc">{tr(step.description, lang)}</p>
                            </div>
                        </div>
                    ))}
                </div>
                <div className={`download-cta-demo reveal${isVisible ? ' visible' : ''}`} style={{ transitionDelay: '300ms' }}>
                    <PresetDemo />
                </div>
            </div>
        </section>
    )
}

export default DownloadCTA
