# SuperTrend EA

## Popis
Jednoduchý, ale efektivní Expert Advisor pro MetaTrader 5 založený na populárním indikátoru SuperTrend. EA automaticky otevírá a zavírá pozice na základě změny trendu (červená/zelená čára SuperTrend indikátoru).

## Obchodní logika

### Princip fungování:
- **Zelený trend (UP)**: EA otevře **BUY** pozici
- **Červený trend (DOWN)**: EA otevře **SELL** pozici
- **Změna trendu**: Automaticky zavře aktuální pozici a otevře novou v opačném směru
- **Vždy pouze 1 pozice**: EA drží maximálně jednu otevřenou pozici najednou

### Jak to funguje:
1. EA čeká na zavření baru
2. Vypočítá SuperTrend indikátor (zelená/červená čára)
3. Když se trend změní z červené na zelenou:
   - Zavře SELL pozici (pokud je otevřená)
   - Okamžitě otevře BUY pozici
4. Když se trend změní ze zelené na červenou:
   - Zavře BUY pozici (pokud je otevřená)
   - Okamžitě otevře SELL pozici

## Instalace

### Krok 1: Přidání do MetaTrader 5
1. Zkopírujte `SuperTrend_EA.mq5` do složky `MQL5/Experts/`
2. Otevřete MetaEditor (F4 v MT5)
3. Najděte soubor v Navigator a zkompilujte (F7)
4. Restartujte MetaTrader 5

### Krok 2: Přidání SuperTrend indikátoru
EA používá vlastní kalkulaci SuperTrend, ale doporučuji přidat SuperTrend indikátor na graf pro vizuální kontrolu:
1. Stáhněte SuperTrend indikátor (dostupný v CodeBase)
2. Vložte do složky `MQL5/Indicators/`
3. Přidejte na graf

### Krok 3: Spuštění EA
1. Přetáhněte `SuperTrend_EA` na požadovaný graf
2. Nastavte parametry (viz níže)
3. Povolte AutoTrading (Ctrl+E)

## Parametry

### SuperTrend Nastavení
- **SuperTrend_Period** (10): Perioda pro ATR kalkulaci
  - Nižší hodnota = citlivější na změny trendu
  - Vyšší hodnota = méně falešných signálů
  - Doporučeno: 10-14

- **SuperTrend_Multiplier** (3.0): Multiplikátor pro pásma SuperTrend
  - Nižší hodnota = více obchodů, více falešných signálů
  - Vyšší hodnota = méně obchodů, lepší signály
  - Doporučeno: 2.5-3.5

### Risk Management
- **LotSize** (0.01): Pevná velikost pozice v lotech
  - Upravte podle velikosti účtu
  - Pro 1000 USD účet: 0.01-0.05
  - Pro 10000 USD účet: 0.1-0.5

- **StopLossPips** (50): Stop Loss v pipech
  - 0 = bez stop loss (ne doporučeno!)
  - Doporučeno: 30-100 pipů
  - Upravte podle volatility symbolu

- **TakeProfitPips** (100): Take Profit v pipech
  - 0 = bez take profit (řízeno pouze trendem)
  - Doporučeno: 50-200 pipů nebo 0 (nechat trend rozhodnout)

### Ostatní
- **MagicNumber** (54321): Unikátní identifikátor pro pozice tohoto EA
- **TradeComment** ("SuperTrend_EA"): Komentář k otevřeným pozicím

## Doporučené nastavení pro různé timeframy

### M15 (15 minut) - Scalping
```
SuperTrend_Period: 10
SuperTrend_Multiplier: 2.5
StopLossPips: 20
TakeProfitPips: 40
```

### H1 (1 hodina) - Intraday
```
SuperTrend_Period: 10
SuperTrend_Multiplier: 3.0
StopLossPips: 50
TakeProfitPips: 100
```

### H4 (4 hodiny) - Swing Trading
```
SuperTrend_Period: 14
SuperTrend_Multiplier: 3.5
StopLossPips: 100
TakeProfitPips: 0 (nechat běžet s trendem)
```

### D1 (denní) - Position Trading
```
SuperTrend_Period: 14
SuperTrend_Multiplier: 4.0
StopLossPips: 200
TakeProfitPips: 0 (nechat běžet s trendem)
```

## Doporučené symboly
- **Forex páry**: EURUSD, GBPUSD, USDJPY, AUDUSD
- **Krypto**: BTCUSD, ETHUSD (vyšší volatilita - opatrně s lot size!)
- **Komodity**: XAUUSD (zlato), USOIL
- **Indexy**: US30, US500, NAS100

## Výhody EA
✓ **Jednoduchá logika**: Srozumitelná strategie bez složitých podmínek  
✓ **Trend following**: Jede s trendem, ne proti němu  
✓ **Automatická správa**: Zavírá staré a otevírá nové pozice automaticky  
✓ **Vizuální kontrola**: Vidíte SuperTrend přímo na grafu  
✓ **Nízká údržba**: Nevyžaduje časté kontroly  

## Nevýhody a rizika
⚠ **Ranging markets**: Může generovat ztráty v postranním trhu  
⚠ **Whipsaws**: Falešné signály při nízké volatilitě  
⚠ **Bez money management**: Používá pevnou velikost pozice  
⚠ **Bez drawdown protection**: Neobsahuje ochranu před velkými ztrátami  

## Tipy pro úspěšné použití

1. **Testujte na demo účtu**: Vždy nejprve otestujte strategii
2. **Používejte v trendových trzích**: SuperTrend funguje nejlépe v jasných trendech
3. **Kombinujte timeframy**: Použijte vyšší timeframe pro určení hlavního trendu
4. **Sledujte výsledky**: Pravidelně kontrolujte výkonnost a upravujte parametry
5. **Risk management**: Neriskujte více než 1-2% účtu na obchod
6. **Neobchodujte při news**: Vypínejte EA před důležitými zprávami

## Backtesting doporučení
- Minimální testovací období: 3-6 měsíců
- Testujte na různých symbolech
- Optimalizujte SuperTrend_Period a Multiplier
- Hledejte konzistentní výsledky, ne nejvyšší profit

## Upozornění
Tento EA je určen pouze pro vzdělávací a testovací účely. Trading s využitím automatizovaných systémů nese riziko ztráty kapitálu. Vždy testujte na demo účtu před nasazením na reálný účet. Autor nenesie odpovědnost za případné ztráty.

## Verze
- **Verze**: 1.0
- **Datum**: Říjen 2025
- **Kompatibilita**: MetaTrader 5
- **Autor**: AOS Development

## Changelog
### v1.0 (Říjen 2025)
- Počáteční verze
- Implementace základní SuperTrend logiky
- Automatické otevírání/zavírání pozic při změně trendu
- Vlastní kalkulace SuperTrend indikátoru