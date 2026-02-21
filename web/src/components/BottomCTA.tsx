import './BottomCTA.css'
import { useI18n, tr } from '../i18n'
import { useScrollReveal } from '../hooks/useScrollReveal'

function BottomCTA() {
    const { lang, t } = useI18n()
    const { ref, isVisible } = useScrollReveal()

    return (
        <section
            className="bottom-cta section"
            ref={ref as React.RefObject<HTMLElement>}
        >
            <div className="bottom-cta-glow" aria-hidden="true" />
            <div className="bottom-cta-inner container">
                <p className={`bottom-cta-tagline reveal${isVisible ? ' visible' : ''}`}>
                    {tr(t.footer.tagline, lang)}
                </p>
                <a
                    href="https://github.com/MUTRO888/Yisi/releases"
                    className={`bottom-cta-btn reveal${isVisible ? ' visible' : ''}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ transitionDelay: '100ms' }}
                >
                    {tr(t.downloadCTA.button, lang)}
                </a>
                <div className={`bottom-cta-meta reveal${isVisible ? ' visible' : ''}`} style={{ transitionDelay: '200ms' }}>
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
