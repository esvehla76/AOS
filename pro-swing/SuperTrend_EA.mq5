//+------------------------------------------------------------------+
//|                                               SuperTrend_EA.mq5 |
//|                                  Copyright 2025, AOS Development |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AOS Development"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Vstupní parametry
input group "=== SuperTrend Nastavení ==="
input int SuperTrend_Period = 10;                  // SuperTrend perioda
input double SuperTrend_Multiplier = 3.0;          // SuperTrend multiplikátor

input group "=== Risk Management ==="
input double LotSize = 0.01;                       // Velikost lotu
input double StopLossPips = 50.0;                  // Stop Loss v pipech (0 = vypnuto)
input double TakeProfitPips = 100.0;               // Take Profit v pipech (0 = vypnuto)

input group "=== Ostatní ==="
input int MagicNumber = 54321;                     // Magic number pro identifikaci
input string TradeComment = "SuperTrend_EA";       // Komentář k pozicím

//--- Globální proměnné
datetime lastBarTime = 0;
int lastTrend = 0; // 1 = UP (zelený), -1 = DOWN (červený), 0 = neurčeno

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Inicializace lastBarTime na aktuální bar
    lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    // Zápis do souboru pro debug
    int fileHandle = FileOpen("SuperTrend_EA_Debug.txt", FILE_WRITE|FILE_TXT|FILE_ANSI);
    if(fileHandle != INVALID_HANDLE)
    {
        FileWrite(fileHandle, "==============================================");
        FileWrite(fileHandle, "SuperTrend EA SPUŠTĚN!");
        FileWrite(fileHandle, "Symbol: " + _Symbol);
        FileWrite(fileHandle, "Timeframe: " + EnumToString(PERIOD_CURRENT));
        FileWrite(fileHandle, "==============================================");
        FileClose(fileHandle);
    }
    
    Print("==============================================");
    Print("SuperTrend EA inicializován úspěšně");
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(PERIOD_CURRENT));
    Print("SuperTrend Perioda: ", SuperTrend_Period);
    Print("SuperTrend Multiplikátor: ", SuperTrend_Multiplier);
    Print("Lot Size: ", LotSize);
    Print("Používám vlastní ATR-based SuperTrend kalkulaci");
    Print("LastBarTime: ", TimeToString(lastBarTime));
    Print("==============================================");
    
    // Alert pro ověření
    Comment("SuperTrend EA běží na ", _Symbol);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("SuperTrend EA ukončen");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Kontrola nového baru
    if(!IsNewBar())
        return;
    
    datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    Print("========================================");
    Print("=== NOVÝ BAR: ", TimeToString(barTime), " ===");
    
    // Získání SuperTrend signálu
    int currentTrend = GetSuperTrendSignal();
    
    if(currentTrend == 0)
    {
        Print("!!! CHYBA: Neplatný SuperTrend signál !!!");
        return;
    }
    
    string trendText = currentTrend == 1 ? "UP (zelený/BUY)" : "DOWN (červený/SELL)";
    string lastTrendText = lastTrend == 1 ? "UP" : (lastTrend == -1 ? "DOWN" : "ŽÁDNÝ");
    
    Print("Aktuální trend: ", trendText);
    Print("Předchozí trend: ", lastTrendText);
    Print("Má se otevřít pozice? lastTrend=", lastTrend, " currentTrend=", currentTrend);
    
    // Detekce změny trendu
    if(lastTrend != 0 && currentTrend != lastTrend)
    {
        Print("╔════════════════════════════════════╗");
        Print("║   !!! ZMĚNA TRENDU !!!            ║");
        Print("╚════════════════════════════════════╝");
        Print("Směr: ", lastTrendText, " -> ", trendText);
        Print("PODMÍNKA SPLNĚNA: lastTrend(", lastTrend, ") != 0 && currentTrend(", currentTrend, ") != lastTrend");
        
        // Zavření existující pozice
        Print("Krok 1: Zavírám starou pozici...");
        CloseCurrentPosition();
        
        // Krátká pauza v testeru
        Sleep(50);
        
        // Otevření nové pozice podle nového trendu
        Print("Krok 2: Otevírám novou pozici...");
        if(currentTrend == 1)
        {
            Print(">> Pokus o OPEN BUY (trend = UP/zelený)");
            OpenPosition(ORDER_TYPE_BUY);
        }
        else if(currentTrend == -1)
        {
            Print(">> Pokus o OPEN SELL (trend = DOWN/červený)");
            OpenPosition(ORDER_TYPE_SELL);
        }
    }
    else if(lastTrend == 0 && currentTrend != 0)
    {
        Print("╔════════════════════════════════════╗");
        Print("║   !!! PRVNÍ SIGNÁL !!!            ║");
        Print("╚════════════════════════════════════╝");
        Print("PODMÍNKA SPLNĚNA: lastTrend == 0 && currentTrend != 0");
        Print("Otevírám první pozici: ", trendText);
        
        if(currentTrend == 1)
        {
            Print(">> Pokus o OPEN BUY (první pozice, trend = UP/zelený)");
            OpenPosition(ORDER_TYPE_BUY);
        }
        else
        {
            Print(">> Pokus o OPEN SELL (první pozice, trend = DOWN/červený)");
            OpenPosition(ORDER_TYPE_SELL);
        }
    }
    else
    {
        Print("❌ PODMÍNKA NESPLNĚNA - žádná akce");
        Print("   Důvod: lastTrend=", lastTrend, " currentTrend=", currentTrend);
        if(lastTrend == currentTrend)
            Print("   -> Trend beze změny");
        else
            Print("   -> Jiný důvod");
    }
    
    // Uložení aktuálního trendu
    lastTrend = currentTrend;
    Print("========================================");
}

//+------------------------------------------------------------------+
//| Kontrola nového baru                                            |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    if(lastBarTime != currentBarTime)
    {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Získání SuperTrend signálu                                      |
//+------------------------------------------------------------------+
int GetSuperTrendSignal()
{
    // Kalkulace SuperTrend podle originální logiky
    double atr[];
    double high[];
    double low[];
    double close[];
    
    ArraySetAsSeries(atr, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    // Získání dat
    static int atrHandle = INVALID_HANDLE;
    if(atrHandle == INVALID_HANDLE)
    {
        atrHandle = iATR(_Symbol, PERIOD_CURRENT, SuperTrend_Period);
        if(atrHandle == INVALID_HANDLE)
        {
            Print("Chyba při vytváření ATR handleru");
            return 0;
        }
    }
    
    // Potřebujeme data pro aktuální a předchozí bar (0 = aktuální, 1 = předchozí)
    int atrCopied = CopyBuffer(atrHandle, 0, 0, 3, atr);
    int highCopied = CopyHigh(_Symbol, PERIOD_CURRENT, 0, 3, high);
    int lowCopied = CopyLow(_Symbol, PERIOD_CURRENT, 0, 3, low);
    int closeCopied = CopyClose(_Symbol, PERIOD_CURRENT, 0, 3, close);
    
    if(atrCopied < 3 || highCopied < 3 || lowCopied < 3 || closeCopied < 3)
    {
        Print("!!! CHYBA při získávání dat !!!");
        Print("ATR copied: ", atrCopied, " | High: ", highCopied, " | Low: ", lowCopied, " | Close: ", closeCopied);
        return 0;
    }
    
    Print("Data načtena OK:");
    Print("  Bar[0] (aktuální): Close=", close[0], " High=", high[0], " Low=", low[0], " ATR=", atr[0]);
    Print("  Bar[1] (předchozí): Close=", close[1], " High=", high[1], " Low=", low[1], " ATR=", atr[1]);
    
    // Static proměnné pro uchování stavu mezi bary
    static double longStop = 0;
    static double shortStop = 0;
    static int supertrend_dir = 0;
    
    // Kalkulace pro aktuální bar (index 0 = poslední uzavřený bar)
    double srcPrice = (high[0] + low[0]) / 2.0;  // PRICE_MEDIAN
    
    // Kalkulace long stop (support - používá se při uptrend)
    double newLongStop = srcPrice - (SuperTrend_Multiplier * atr[0]);
    
    // Inicializace při prvním spuštění
    if(longStop == 0 && shortStop == 0)
    {
        longStop = newLongStop;
        shortStop = srcPrice + (SuperTrend_Multiplier * atr[0]);
        
        // Určení počátečního směru
        if(close[0] > srcPrice)
        {
            supertrend_dir = 1;  // UP trend
            Print("SuperTrend inicializován: UP | Close: ", close[0], " | Median: ", srcPrice);
        }
        else
        {
            supertrend_dir = -1; // DOWN trend
            Print("SuperTrend inicializován: DOWN | Close: ", close[0], " | Median: ", srcPrice);
        }
        
        return supertrend_dir;
    }
    
    // TRAILING STOP LOGIKA - klíčová část!
    // Long stop se může jen zvyšovat (nikdy nesnižovat)
    if(newLongStop > longStop || low[0] <= longStop)
        longStop = newLongStop;
    
    // Kalkulace short stop (resistance - používá se při downtrend)
    double newShortStop = srcPrice + (SuperTrend_Multiplier * atr[0]);
    
    // Short stop se může jen snižovat (nikdy nezvyšovat)
    if(newShortStop < shortStop || high[0] >= shortStop)
        shortStop = newShortStop;
    
    // ZMĚNA TRENDU - podle originálního indikátoru
    int prevTrend = supertrend_dir;
    
    // Změna z DOWN na UP: když HIGH přesáhne předchozí shortStop
    if(supertrend_dir == -1 && high[0] > shortStop)
    {
        supertrend_dir = 1;
        longStop = newLongStop;  // Reset long stop při změně
        Print(">>> ZMĚNA TRENDU: DOWN -> UP <<<");
        Print("High[0]: ", high[0], " > ShortStop: ", shortStop);
    }
    // Změna z UP na DOWN: když LOW klesne pod předchozí longStop
    else if(supertrend_dir == 1 && low[0] < longStop)
    {
        supertrend_dir = -1;
        shortStop = newShortStop; // Reset short stop při změně
        Print(">>> ZMĚNA TRENDU: UP -> DOWN <<<");
        Print("Low[0]: ", low[0], " < LongStop: ", longStop);
    }
    
    // Debug info - bez kreslení (to bude v OnCalculate)
    if(supertrend_dir == 1)
    {
        Print("🟢 UP TREND (ZELENÁ)");
        Print("   LongStop: ", DoubleToString(longStop, _Digits));
        Print("   Close[0]=", close[0], " > LongStop (OK pro BUY)");
    }
    else
    {
        Print("🔴 DOWN TREND (ČERVENÁ)");
        Print("   ShortStop: ", DoubleToString(shortStop, _Digits));
        Print("   Close[0]=", close[0], " < ShortStop (OK pro SELL)");
    }
    
    return supertrend_dir;
}

//+------------------------------------------------------------------+
//| Otevření pozice                                                  |
//+------------------------------------------------------------------+
void OpenPosition(ENUM_ORDER_TYPE orderType)
{
    Print(">> OpenPosition zavoláno pro: ", EnumToString(orderType));
    
    // Kontrola, zda již není otevřená pozice
    if(HasOpenPosition())
    {
        Print("!!! Pozice již existuje, nemohu otevřít novou !!!");
        return;
    }
    
    Print("Žádná existující pozice - pokračuji s otevřením");
    
    double price, sl = 0, tp = 0;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    Print("Symbol info - Point: ", point, " | Digits: ", digits);
    
    // Nastavení ceny
    if(orderType == ORDER_TYPE_BUY)
    {
        price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        if(StopLossPips > 0)
            sl = price - (StopLossPips * point * 10);
        if(TakeProfitPips > 0)
            tp = price + (TakeProfitPips * point * 10);
    }
    else // SELL
    {
        price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        if(StopLossPips > 0)
            sl = price + (StopLossPips * point * 10);
        if(TakeProfitPips > 0)
            tp = price - (TakeProfitPips * point * 10);
    }
    
    // Normalizace hodnot
    price = NormalizeDouble(price, digits);
    if(sl > 0) sl = NormalizeDouble(sl, digits);
    if(tp > 0) tp = NormalizeDouble(tp, digits);
    
    Print("Normalizované hodnoty - Price: ", price, " | SL: ", sl, " | TP: ", tp);
    
    // Vytvoření objednávky
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = LotSize;
    request.type = orderType;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.magic = MagicNumber;
    request.comment = TradeComment;
    request.deviation = 10;
    
    Print("Odesílám objednávku - Symbol: ", _Symbol, " | Volume: ", LotSize, " | Type: ", EnumToString(orderType));
    
    bool orderResult = OrderSend(request, result);
    
    Print("OrderSend dokončeno - Result: ", orderResult, " | RetCode: ", result.retcode);
    if(orderResult && result.retcode == TRADE_RETCODE_DONE)
    {
        Print("✓ Pozice otevřena: ", EnumToString(orderType), 
              " | Lot: ", DoubleToString(LotSize, 2),
              " | Cena: ", DoubleToString(price, digits),
              " | SL: ", sl > 0 ? DoubleToString(sl, digits) : "Žádný",
              " | TP: ", tp > 0 ? DoubleToString(tp, digits) : "Žádný");
    }
    else
    {
        Print("✗ Chyba při otevírání pozice: ", result.retcode, " - ", result.comment);
    }
}

//+------------------------------------------------------------------+
//| Zavření aktuální pozice                                         |
//+------------------------------------------------------------------+
void CloseCurrentPosition()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && PositionSelectByTicket(ticket))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                
                request.action = TRADE_ACTION_DEAL;
                request.symbol = _Symbol;
                request.volume = PositionGetDouble(POSITION_VOLUME);
                request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                               SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                request.position = ticket;
                request.magic = MagicNumber;
                request.comment = "Trend Change Close";
                request.deviation = 10;
                
                bool closeResult = OrderSend(request, result);
                if(closeResult && result.retcode == TRADE_RETCODE_DONE)
                {
                    Print("✓ Pozice uzavřena: Ticket #", ticket);
                }
                else
                {
                    Print("✗ Chyba při uzavírání pozice: ", result.retcode, " - ", result.comment);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Kontrola existující pozice                                      |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+