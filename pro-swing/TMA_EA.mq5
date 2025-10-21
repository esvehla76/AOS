//+------------------------------------------------------------------+
//|                                                       TMA_EA.mq5 |
//|                                  Copyright 2025, AOS Development |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AOS Development"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Vstupní parametry
input group "=== TMA Nastavení ==="
input int                TMA_Period = 14;          // TMA perioda
input ENUM_APPLIED_PRICE TMA_Price  = PRICE_CLOSE; // Price

input group "=== Risk Management ==="
input double LotSize = 0.01;                       // Velikost lotu
input double StopLossPips = 50.0;                  // Stop Loss v pipech (0 = vypnuto)
input double TakeProfitPips = 100.0;               // Take Profit v pipech (0 = vypnuto)

input group "=== Ostatní ==="
input int MagicNumber = 54322;                     // Magic number pro identifikaci
input string TradeComment = "TMA_EA";              // Komentář k pozicím

//--- Globální proměnné
datetime lastBarTime = 0;
int lastColor = 0; // 0 = neurčeno, 1 = růžová (DOWN), 2 = zelená (UP)
bool tradeExecutedOnThisBar = false; // Zabraňuje vícenásobným obchodům na jedné svíčce

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Inicializace lastBarTime na aktuální bar
    lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    // Zjistit aktuální signál
    int currentSignal = GetTMASignal();
    
    Print("==============================================");
    Print("TMA EA inicializován úspěšně");
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(PERIOD_CURRENT));
    Print("TMA Perioda: ", TMA_Period);
    Print("TMA Price: ", EnumToString(TMA_Price));
    Print("Lot Size: ", LotSize);
    Print("LastBarTime: ", TimeToString(lastBarTime));
    Print("Initial Signal: ", currentSignal, " (1=SELL, 2=BUY)");
    
    // Pokud není otevřená pozice a máme platný signál, otevřít ji
    if(currentSignal != 0 && !HasOpenPosition())
    {
        Print("🚀 Inicializace: Otevírám počáteční pozici podle aktuálního signálu");
        
        if(currentSignal == 2)
        {
            Print("Otevírám BUY při startu");
            OpenPosition(ORDER_TYPE_BUY);
        }
        else if(currentSignal == 1)
        {
            Print("Otevírám SELL při startu");
            OpenPosition(ORDER_TYPE_SELL);
        }
        
        lastColor = currentSignal;
        tradeExecutedOnThisBar = true;
    }
    else if(HasOpenPosition())
    {
        Print("⚠️ Již existuje otevřená pozice - neotevírám novou při startu");
        if(currentSignal != 0)
            lastColor = currentSignal;
    }
    else
    {
        Print("⚠️ Neplatný signál při inicializaci - čekám na první platný signál");
    }
    
    Print("==============================================");
    
    Comment("TMA EA běží na ", _Symbol);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("TMA EA ukončen");
    Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Kontrola nového baru
    if(!IsNewBar())
        return;
    
    // Reset flagu pro nový bar
    tradeExecutedOnThisBar = false;
    
    Print("=== NOVÝ BAR ===");
    
    // Získání TMA signálu
    int currentSignal = GetTMASignal();
    
    if(currentSignal == 0)
    {
        Print("CHYBA: Neplatný signál");
        return;
    }
    
    Print("currentSignal=", currentSignal, " lastColor=", lastColor);
    
    // Změna signálu = změna pozice (ale jen pokud jsme už neobchodovali na tomto baru)
    if(currentSignal != lastColor && !tradeExecutedOnThisBar)
    {
        Print("*** ZMĚNA SIGNÁLU: ", lastColor, " -> ", currentSignal, " ***");
        
        // Zavřít starou pozici
        CloseCurrentPosition();
        
        // Otevřít novou podle signálu
        if(currentSignal == 2)
        {
            Print("Otevírám BUY");
            OpenPosition(ORDER_TYPE_BUY);
        }
        else if(currentSignal == 1)
        {
            Print("Otevírám SELL");
            OpenPosition(ORDER_TYPE_SELL);
        }
        
        lastColor = currentSignal;
        tradeExecutedOnThisBar = true; // Označit, že jsme obchodovali
    }
    else
    {
        if(tradeExecutedOnThisBar)
            Print("Obchod již byl proveden na tomto baru");
        else
            Print("Bez změny, signál zůstává: ", currentSignal);
    }
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
//| Získání TMA signálu                                              |
//+------------------------------------------------------------------+
int GetTMASignal()
{
    // Získání dat - potřebujeme víc barů pro TMA výpočet
    int bars_needed = TMA_Period + 10;
    double close[];
    double open[];
    double high[];
    double low[];
    
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    int copied_close = CopyClose(_Symbol, PERIOD_CURRENT, 0, bars_needed, close);
    int copied_open = CopyOpen(_Symbol, PERIOD_CURRENT, 0, bars_needed, open);
    int copied_high = CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars_needed, high);
    int copied_low = CopyLow(_Symbol, PERIOD_CURRENT, 0, bars_needed, low);
    
    Print(">>> GetTMASignal START <<<");
    Print("Požadováno barů: ", bars_needed);
    Print("Zkopírováno: close=", copied_close, " open=", copied_open, " high=", copied_high, " low=", copied_low);
    
    if(copied_close < bars_needed || copied_open < bars_needed || copied_high < bars_needed || copied_low < bars_needed)
    {
        Print("!!! CHYBA při získávání dat - nedostatek barů !!!");
        return 0;
    }
    
    Print("Data načtena OK:");
    Print("  Bar[1]: Close=", close[1], " Open=", open[1], " High=", high[1], " Low=", low[1]);
    Print("  Bar[2]: Close=", close[2], " Open=", open[2], " High=", high[2], " Low=", low[2]);
    
    // Kalkulace TMA pro bar[1] a bar[2] (uzavřené bary)
    double tmaVal1 = CalculateTMA(1, close, open, high, low);
    double tmaVal2 = CalculateTMA(2, close, open, high, low);
    
    Print("TMA[1] = ", DoubleToString(tmaVal1, 5), " | TMA[2] = ", DoubleToString(tmaVal2, 5));
    Print("Close[1] = ", DoubleToString(close[1], 5), " | Close[2] = ", DoubleToString(close[2], 5));
    
    // NOVÁ Strategie: Pozice podle vztahu ceny k TMA
    // BUY: když cena je NAD TMA
    // SELL: když cena je POD TMA
    
    bool isAboveTMA = close[1] > tmaVal1;
    bool isBelowTMA = close[1] < tmaVal1;
    
    Print("Bar[1]: Close", (isBelowTMA ? " POD " : (isAboveTMA ? " NAD " : " = ")), "TMA");
    
    int currentSignal = 0;
    
    // Cena NAD TMA = BUY signál
    if(isAboveTMA)
    {
        currentSignal = 2;  // BUY
        Print("🟢 BUY SIGNÁL - Cena je NAD TMA");
        Print("   Close[1]=", close[1], " > TMA[1]=", tmaVal1);
    }
    // Cena POD TMA = SELL signál
    else if(isBelowTMA)
    {
        currentSignal = 1;  // SELL
        Print("🔴 SELL SIGNÁL - Cena je POD TMA");
        Print("   Close[1]=", close[1], " < TMA[1]=", tmaVal1);
    }
    else
    {
        currentSignal = lastColor;  // Žádná změna
        Print("⚪ Cena = TMA");
    }
    
    Print(">>> GetTMASignal END - vrací: ", currentSignal, " <<<");
    
    return currentSignal;
}

//+------------------------------------------------------------------+
//| Kalkulace Triangular Moving Average pro daný bar                |
//+------------------------------------------------------------------+
double CalculateTMA(int shift, const double &close[], const double &open[], 
                    const double &high[], const double &low[])
{
    Print(">>> CalculateTMA pro shift=", shift, " START <<<");
    
    // Správná TMA kalkulace - SMA of SMA (dvojité vyhlazení)
    int halfPeriod = (int)MathCeil(TMA_Period / 2.0);
    
    Print("TMA_Period=", TMA_Period, " halfPeriod=", halfPeriod);
    
    // Krok 1: Vypočítat první SMA hodnoty
    double firstSMA[];
    ArrayResize(firstSMA, halfPeriod);
    
    for(int i = 0; i < halfPeriod; i++)
    {
        double sum = 0;
        int count = 0;
        
        for(int j = 0; j < halfPeriod; j++)
        {
            int idx = shift + i + j;
            if(idx >= ArraySize(close))
                break;
            
            double p = 0;
            switch(TMA_Price)
            {
                case PRICE_CLOSE:    p = close[idx];                                                    break;
                case PRICE_OPEN:     p = open[idx];                                                     break;
                case PRICE_HIGH:     p = high[idx];                                                     break;
                case PRICE_LOW:      p = low[idx];                                                      break;
                case PRICE_MEDIAN:   p = (high[idx] + low[idx]) / 2.0;                                 break;
                case PRICE_TYPICAL:  p = (high[idx] + low[idx] + close[idx]) / 3.0;                    break;
                case PRICE_WEIGHTED: p = (high[idx] + low[idx] + close[idx] + close[idx]) / 4.0;      break;
                default:             p = close[idx];                                                    break;
            }
            sum += p;
            count++;
        }
        
        if(count > 0)
            firstSMA[i] = sum / count;
        else
            firstSMA[i] = 0;
    }
    
    // Krok 2: Vypočítat druhou SMA (SMA of SMA) = TMA
    double sumTMA = 0;
    int countTMA = 0;
    
    for(int i = 0; i < halfPeriod; i++)
    {
        if(firstSMA[i] != 0)
        {
            sumTMA += firstSMA[i];
            countTMA++;
        }
    }
    
    if(countTMA == 0)
    {
        Print("!!! CHYBA: countTMA=0 v CalculateTMA !!!");
        return 0;
    }
    
    double tmaValue = sumTMA / countTMA;
    
    Print("CalculateTMA shift=", shift, " TMA=", DoubleToString(tmaValue, 5), 
          " (1.SMA count=", halfPeriod, ", 2.SMA count=", countTMA, ")");
    
    return tmaValue;
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
    
    // Zjistit podporovaný filling mode pro symbol
    int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
        request.type_filling = ORDER_FILLING_IOC;
    else if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
        request.type_filling = ORDER_FILLING_FOK;
    else
        request.type_filling = ORDER_FILLING_RETURN;
    
    Print("Odesílám objednávku - Symbol: ", _Symbol, " | Volume: ", LotSize, " | Type: ", EnumToString(orderType), " | Filling: ", request.type_filling);
    
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
                request.comment = "TMA Color Change";
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
