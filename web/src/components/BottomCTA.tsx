import './BottomCTA.css'
import { useI18n, tr } from '../i18n'
import { useScrollReveal } from '../hooks/useScrollReveal'

function BottomCTA() {
    const { lang, t } = useI18n()
    const { ref, isVisible } = useScrollReveal()

    return (
        <section
            className="bottom-cta section section-compact"
            ref={ref as React.RefObject<HTMLElement>}
        >
            <div className="bottom-cta-inner container">
                <a
                    href="https://github.com/MUTRO888/Yisi/releases"
                    className={`bottom-cta-btn reveal${isVisible ? ' visible' : ''}`}
                    target="_blank"
                    rel="noopener noreferrer"
                >
                    {tr(t.downloadCTA.button, lang)}
                </a>
                <div className={`bottom-cta-meta reveal${isVisible ? ' visible' : ''}`} style={{ transitionDelay: '100ms' }}>
                    <span className="bottom-cta-req">
                        {tr(t.downloadCTA.requires, lang)}
                    </span>
                    <span className="bottom-cta-sep" aria-hidden="true" />
                    <a
                        href="https://github.com/MUTRO888/Yisi"
                        className="bottom-cta-source"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        {tr(t.downloadCTA.source, lang)}
                    </a>
                </div>
            </div>
        </section>
    )
}

export default BottomCTA
