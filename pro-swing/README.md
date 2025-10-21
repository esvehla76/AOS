# Fintokei PRO Swing EA

## Popis
Swingový AOS (Automated Trading System) pro MetaTrader 5 navržený speciálně k absolvování Fintokei výzvy PRO Swing. Expert Advisor využívá kombinaci technických indikátorů pro identifikaci kvalitních swing obchodů s důrazem na risk management a dodržení pravidel výzvy.

## Přehled funkcí
- **Risk Management**: Automatické kalkulace velikosti pozice na základě ATR a nastaveného rizika
- **Trend Filtry**: EMA crossover systém pro identifikaci směru trendu
- **RSI Pullback**: Vstup do pozic během korekcí v trendu pomocí RSI
- **ATR Position Sizing**: Dynamické stanovení velikosti pozice podle volatility
- **Drawdown Protection**: Automatická blokace vstupů při dosažení denního nebo celkového drawdownu
- **Multi-Symbol Support**: Optimalizováno pro hlavní Fintokei symboly
- **H4 Timeframe**: Navrženo pro 4hodinové grafy pro swing trading

## Instalace
1. Zkopírujte soubor `Fintokei_PRO_Swing_EA.mq5` do složky `MQL5/Experts/` ve vašem MetaTrader 5
2. Otevřete MetaEditor (F4 v MT5)
3. Najděte soubor v Navigator a zkompilujte jej (F7)
4. Restartujte MetaTrader 5
5. Připojte EA k H4 grafu požadovaného symbolu
6. Nastavte správné parametry podle velikosti účtu a pravidel výzvy

## Parametry

### Risk Management
- **RiskPercent** (1.0): Procento rizika na obchod (doporučeno 1-2%)
- **MaxDailyDrawdownPercent** (5.0): Maximální denní drawdown v % před blokací
- **MaxTotalDrawdownPercent** (10.0): Maximální celkový drawdown v % před blokací

### Technické indikátory
- **EMA_Fast_Period** (21): Perioda rychlé EMA pro trend filtr
- **EMA_Slow_Period** (50): Perioda pomalé EMA pro trend filtr
- **RSI_Period** (14): Perioda RSI pro pullback signály
- **RSI_Oversold** (30): RSI úroveň pro nákup pullback
- **RSI_Overbought** (70): RSI úroveň pro prodej pullback

### ATR Nastavení
- **ATR_Period** (14): Perioda ATR pro volatility kalkulace
- **ATR_Multiplier** (2.0): Multiplikátor ATR pro stop loss
- **ATR_TP_Ratio** (2.0): Poměr Take Profit k Stop Loss

### Obchodní okna
- **StartHour** (8): Začátek obchodování (GMT)
- **EndHour** (18): Konec obchodování (GMT)

## Testovací podmínky
- **Testovací účet**: 1 000 000 CZK
- **Symboly**: EURUSDp, XAUUSDp, US100p, US500p, USOILp
- **Timeframe**: H4 (4 hodiny)
- **Pravidla**: Fintokei PRO Swing výzva

## Pravidla Fintokei PRO Swing
- Maximální denní ztráta: 5% z počátečního zůstatku
- Maximální celková ztráta: 10% z počátečního zůstatku
- Minimální obchodní dny: 10 dní
- Profit target: 8% z počátečního zůstatku

## Upozornění
Tento EA je určen pouze pro testovací a vzdělávací účely. Vždy si ověřte nastavení před použitím na reálném účtu. Autor nenesie odpovědnost za případné ztráty.

## Verze
- **Verze**: 1.0
- **Datum**: Říjen 2025
- **Kompatibilita**: MetaTrader 5