import './Features.css'

const features = [
    {
        title: 'On-Device Translation',
        description: 'All processing happens locally. Your data never leaves your Mac.',
    },
    {
        title: 'OCR Capture',
        description: 'Select any region of your screen to recognize and translate text instantly.',
    },
    {
        title: 'AI Optimization',
        description: 'Optional AI-powered refinement for more natural, context-aware translations.',
    },
]

function Features() {
    return (
        <section id="features" className="features section">
            <div className="features-inner container">
                <h2 className="features-heading">Designed for clarity.</h2>
                <div className="features-grid">
                    {features.map((f) => (
                        <article key={f.title} className="feature-card">
                            <h3 className="feature-title">{f.title}</h3>
                            <p className="feature-desc">{f.description}</p>
                        </article>
                    ))}
                </div>
            </div>
        </section>
    )
}

export default Features
