# TMA EA (Triangular Moving Average Expert Advisor)

## ✅ Status: FUNKČNÍ - OBCHODUJE!

EA úspěšně otevírá a zavírá pozice. Ziskovost závisí na parametrech, symbolu a timeframu.

## Popis strategie

EA obchoduje na základě vztahu ceny k TMA:
- **BUY signál**: Když zavírací cena je **NAD** TMA
- **SELL signál**: Když zavírací cena je **POD** TMA

Při změně signálu EA:
1. Zavře aktuální pozici
2. Otevře novou pozici v opačném směru

## Funkce

- ✅ Automatické obchodování podle TMA signálů
- ✅ Nastavitelná perioda TMA
- ✅ Konfigurovatelný risk management (lot size, SL, TP)
- ✅ **Automatická detekce filling mode brokera** (IOC/FOK/RETURN)
- ✅ Magic number pro identifikaci obchodů
- ✅ Rozsáhlé debug logování

## Parametry

### TMA Nastavení
- **TMA_Period** (14): Perioda pro výpočet TMA
  - Nižší hodnoty (8-12) = citlivější, více obchodů
  - Vyšší hodnoty (16-20) = méně falešných signálů
- **TMA_Price** (PRICE_CLOSE): Typ ceny pro výpočet
  - PRICE_CLOSE: Standardní zavírací cena
  - PRICE_TYPICAL: (H+L+C)/3 - vyhlazené

### Risk Management
- **LotSize** (0.01): Velikost obchodního lotu
- **StopLossPips** (50.0): Stop Loss v pipech (0 = vypnuto)
- **TakeProfitPips** (100.0): Take Profit v pipech (0 = vypnuto)

### Ostatní
- **MagicNumber** (54322): Unikátní identifikátor pro obchody EA
- **TradeComment** ("TMA_EA"): Komentář k pozicím

## Optimalizace - Doporučené kombinace

### Forex páry (EURUSD, GBPUSD):
- **Timeframe**: H4
- **TMA_Period**: 12-16
- **StopLoss**: 50-80 pips
- **TakeProfit**: 100-150 pips

### Indexy (US500, DE40):
- **Timeframe**: H1-H4
- **TMA_Period**: 10-14
- **StopLoss**: 30-50 pips
- **TakeProfit**: 60-100 pips

### Commodities (XAUUSD):
- **Timeframe**: H4-D1
- **TMA_Period**: 14-20
- **StopLoss**: 100-200 pips
- **TakeProfit**: 200-400 pips

## Jak to funguje

1. EA kontroluje každý nový bar (OnTick + IsNewBar)
2. Vypočítá TMA hodnotu pomocí dvojitého SMA vyhlazení
3. Porovná Close[1] s TMA[1]
4. Detekuje změnu signálu (NAD → POD nebo POD → NAD)
5. Při změně:
   - Zavře existující pozici (CloseCurrentPosition)
   - Otevře novou v novém směru (OpenPosition)
6. **Automaticky detekuje správný filling mode brokera**

## Výhody a nevýhody

### ✅ Výhody:
- Jednoduchá, jasná strategie
- Automatické otáčení pozic
- Funguje na trendových trzích
- Nízké nároky na data
- **Automatická kompatibilita s různými brokery**

### ⚠️ Nevýhody:
- Časté přepínání v ranging trzích
- Může mít mnoho malých ztrát
- Potřebuje silný trend pro zisk
- TMA se zpožďuje za cenou

## Troubleshooting

### ✅ EA neotvírá obchody - VYŘEŠENO
**Problém**: Filling mode error 10030  
**Řešení**: EA nyní automaticky detekuje podporovaný filling mode (IOC/FOK/RETURN)

### Příliš mnoho obchodů
- Zvyšte TMA_Period (na 16-20)
- Přejděte na vyšší timeframe (H4 → D1)

### Málo obchodů
- Snižte TMA_Period (na 10-12)
- Přejděte na nižší timeframe (H4 → H1)

## Technické detaily

### TMA Kalkulace
```
halfPeriod = ceil(TMA_Period / 2)

Krok 1: Vypočítat SMA hodnoty
  Pro každý i od 0 do halfPeriod:
    sma[i] = Average(price[i...i+halfPeriod])

Krok 2: Vypočítat TMA (SMA of SMA)
  tma = Average(sma[0...halfPeriod])
```

### Signály
```cpp
if (Close[1] > TMA[1])
    → BUY signál
    
if (Close[1] < TMA[1])
    → SELL signál
    
if (currentSignal != lastSignal)
    → Zavři starou pozici
    → Otevři novou
```

### Filling Mode Detection
```cpp
int filling = SymbolInfoInteger(Symbol, SYMBOL_FILLING_MODE);

if (filling & SYMBOL_FILLING_IOC)
    → použít IOC
else if (filling & SYMBOL_FILLING_FOK)
    → použít FOK
else
    → použít RETURN
```

## Instalace a spuštění

1. **Zkopírujte** `TMA_EA.mq5` do složky `MQL5/Experts/`
2. **Zkompilujte** soubor v MetaEditoru (F7)
3. **Přetáhněte** EA na graf v MT5
4. **Povolte** AutoTrading (zelené tlačítko)
5. **Zkontrolujte** Journal pro výpisy EA

## Testování

### Backtest doporučení:
1. **Mode**: "Every tick" nebo "OHLC prices"
2. **Období**: Minimálně 6 měsíců
3. **Symboly**: Testovat více párů současně
4. **Optimalizace**: TMA_Period v rozsahu 8-20

### Forward test:
- Spustit na **demo účtu** minimálně 1 měsíc
- Sledovat **drawdown** a počet obchodů
- Upravit parametry podle výsledků
- Testovat různé timeframy

## Changelog

### v1.00 (2025-10-21) - První funkční verze
- ✅ Základní TMA strategie (cena vs TMA)
- ✅ Risk management (SL/TP)
- ✅ **Automatická detekce filling mode**
- ✅ Debug logování
- ✅ Oprava: EA nyní úspěšně obchoduje
- ✅ Kompatibilita s různými brokery

### Známé problémy
- ~~Filling mode error 10030~~ ✅ OPRAVENO
- ~~EA neotvírá obchody~~ ✅ OPRAVENO
- TMA kalkulace je zjednodušená (double SMA, ne plná TMA)

### Budoucí vylepšení
- [ ] Plná TMA kalkulace s lineárními váhami
- [ ] Integrace s externí TMA indicator přes iCustom()
- [ ] Trailing stop funkcionalita
- [ ] Break-even management
- [ ] Filtr pro ranging trhy (ADX, ATR)
- [ ] Multi-timeframe konfirmace

---

**Autor**: AOS Development  
**Datum**: 2025-10-21  
**MT5 Build**: 5370+  
**Tested on**: PurpleTradingSC-01MT5  
**Status**: ✅ Funkční a obchodující
