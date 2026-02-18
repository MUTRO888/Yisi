import './AppDemo.css'
import { useI18n, tr } from '../i18n'
import { useScrollReveal } from '../hooks/useScrollReveal'
import TextReveal from './TextReveal'

function WhyYisi() {
    const { lang, t } = useI18n()
    const { ref, isVisible } = useScrollReveal()

    return (
        <section
            id="why-yisi"
            className="why-yisi section"
            ref={ref as React.RefObject<HTMLElement>}
        >
            <div className="why-yisi-inner container">
                <TextReveal
                    text={tr(t.whyYisi.heading, lang)}
                    isVisible={isVisible}
                    className="why-yisi-heading"
                />
                <p className={`why-yisi-sub reveal${isVisible ? ' visible' : ''}`}>
                    {tr(t.whyYisi.sub, lang)}
                </p>
                <div className={`why-yisi-grid reveal-stagger${isVisible ? ' visible' : ''}`}>
                    {t.whyYisi.items.map((item, i) => (
                        <div
                            key={item.title.en}
                            className="why-yisi-card reveal-child"
                            style={{ '--reveal-index': i } as React.CSSProperties}
                        >
                            <h3 className="why-yisi-title">{tr(item.title, lang)}</h3>
                            <p className="why-yisi-desc">{tr(item.description, lang)}</p>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    )
}

export default WhyYisi
