import './Features.css'
import { useI18n, tr } from '../i18n'
import { useScrollReveal } from '../hooks/useScrollReveal'
import TextReveal from './TextReveal'

function Features() {
    const { lang, t } = useI18n()
    const { ref, isVisible } = useScrollReveal()

    return (
        <section
            id="features"
            className="features section"
            ref={ref as React.RefObject<HTMLElement>}
        >
            <div className="features-inner container">
                <TextReveal
                    text={tr(t.features.heading, lang)}
                    isVisible={isVisible}
                    className="features-heading"
                />
                <div className={`features-grid reveal-stagger${isVisible ? ' visible' : ''}`}>
                    {t.features.items.map((f, i) => (
                        <article
                            key={f.title.en}
                            className={`feature-card reveal-child`}
                            style={{ '--reveal-index': i } as React.CSSProperties}
                        >
                            <span className="feature-label">{tr(f.label, lang)}</span>
                            <h3 className="feature-title">{tr(f.title, lang)}</h3>
                            <p className="feature-desc">{tr(f.description, lang)}</p>
                        </article>
                    ))}
                </div>
            </div>
        </section>
    )
}

export default Features
