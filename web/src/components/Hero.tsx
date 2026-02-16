import './Hero.css'

function Hero() {
    return (
        <section className="hero section">
            <div className="hero-inner container">
                <h1 className="hero-title">Yisi</h1>
                <p className="hero-slogan">Always room for improvement.</p>
                <p className="hero-description">
                    A privacy-first, native macOS translation tool.<br />
                    Powered by on-device intelligence. Fast, elegant, and offline-capable.
                </p>
                <div className="hero-actions">
                    <a
                        href="https://github.com/MUTRO888/Yisi/releases"
                        className="btn btn-primary"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        Download
                    </a>
                    <a href="#features" className="btn btn-ghost">
                        Learn More
                    </a>
                </div>
            </div>
        </section>
    )
}

export default Hero
