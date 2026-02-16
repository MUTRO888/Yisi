import './Header.css'

function Header() {
    return (
        <header className="header">
            <div className="header-inner container">
                <a href="/" className="header-logo">Yisi</a>
                <nav className="header-nav">
                    <a href="#features" className="header-link">Features</a>
                    <a
                        href="https://github.com/MUTRO888/Yisi"
                        className="header-link"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        GitHub
                    </a>
                </nav>
            </div>
        </header>
    )
}

export default Header
