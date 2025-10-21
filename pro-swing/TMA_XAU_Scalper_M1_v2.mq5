//+------------------------------------------------------------------+
//|                                     TMA_XAU_Scalper_M1_v2.mq5   |
//|                                  Copyright 2025, AOS Development |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AOS Development"
#property link      "https://www.mql5.com"
#property version   "3.00"
#property strict
#property description "EMA Pullback Scalper (univerzální) s RSI a ATR filtry"

//--- Vstupní parametry
input group "=== EMA Nastavení ==="
input int                EMA_Fast_Period = 9;               // Rychlá EMA
input int                EMA_Slow_Period = 21;              // Pomalá EMA
input ENUM_APPLIED_PRICE EMA_Price       = PRICE_CLOSE;     // Typ ceny pro EMA
input double             PullbackTolerance = 1500.0;        // Tolerance pullback v bodech (pro XAUUSD: 100 bodů = 1 USD)

input group "=== RSI Filtr ==="
input bool   UseRSIFilter   = false;                        // Použít RSI filtr (doporučeno: false pro více obchodů)
input int    RSI_Period     = 14;                           // RSI perioda
input double RSI_BuyLevel   = 45.0;                         // RSI úroveň pro BUY (pullback v uptrendu) - pouze pokud UseRSIFilter=true
input double RSI_SellLevel  = 55.0;                         // RSI úroveň pro SELL (pullback v downtrendu) - pouze pokud UseRSIFilter=true

input group "=== ATR Filtr ==="
input int    ATR_Period         = 14;                       // ATR perioda
input double ATR_MinVolatility  = 0.1;                      // Min volatilita (ATR)

input group "=== Spread Filter ==="
input double Max_Spread = 1.0;                              // Max spread v USD

input group "=== Risk Management ==="
input double TakeProfitPips = 25.0;                         // Take Profit v pipech
input double StopLossPips   = 12.0;                         // Stop Loss v pipech
input double LotSize        = 0.10;                         // Velikost lotu
input bool   UseMoneyManagement = false;                    // Použít Money Management
input double RiskPercent = 0.5;                             // Riziko v % účtu (pokud MM=true)

input group "=== Trading Time ==="
input string TradingStart = "08:00";                        // Start obchodování (HH:MM)
input string TradingEnd   = "20:00";                        // Konec obchodování (HH:MM)

input group "=== Debug & Ostatní ==="
input bool   ReverseMode     = false;                       // Obrátit logiku vstupů (BUY↔SELL)
input bool   UseClosedBarEMA = true;                        // Použít hodnoty EMA z uzavřeného baru (stabilnější)
input bool   DebugMode       = true;                        // Detailní debug logy
input int    MagicNumber     = 777002;                      // Magic number
input string TradeComment    = "EMA_Scalper";               // Komentář k pozicím

//--- Globální proměnné
int rsi_handle;        // Handle pro RSI indikátor
int atr_handle;        // Handle pro ATR indikátor
int emaFast_handle;    // Handle pro rychlou EMA
int emaSlow_handle;    // Handle pro pomalou EMA
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Inicializace RSI indikátoru
    rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE)
    {
        Print("❌ CHYBA: Nelze inicializovat RSI indikátor");
        return(INIT_FAILED);
    }
    
    // Inicializace ATR indikátoru
    atr_handle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    if(atr_handle == INVALID_HANDLE)
    {
        Print("❌ CHYBA: Nelze inicializovat ATR indikátor");
        return(INIT_FAILED);
    }

    // Inicializace EMA indikátorů (vrací handle)
    emaFast_handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Fast_Period, 0, MODE_EMA, EMA_Price);
    if(emaFast_handle == INVALID_HANDLE)
    {
        Print("❌ CHYBA: Nelze inicializovat EMA Fast");
        return(INIT_FAILED);
    }
    emaSlow_handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Slow_Period, 0, MODE_EMA, EMA_Price);
    if(emaSlow_handle == INVALID_HANDLE)
    {
        Print("❌ CHYBA: Nelze inicializovat EMA Slow");
        return(INIT_FAILED);
    }
    
    // Inicializace lastBarTime
    lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    Print("==============================================");
    Print("✅ EMA Pullback Scalper v3 inicializován");
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(PERIOD_CURRENT));
    Print("EMA Fast / Slow: ", EMA_Fast_Period, " / ", EMA_Slow_Period);
    Print("Pullback Tolerance: ", PullbackTolerance, " bodů (0=striktní)");
    if(UseRSIFilter)
        Print("RSI Filter: ON | Period: ", RSI_Period, " | Buy<", RSI_BuyLevel, " | Sell>", RSI_SellLevel);
    else
        Print("RSI Filter: OFF (ignoruje RSI podmínky)");
    Print("ATR Period: ", ATR_Period, " | Min Volatility: ", ATR_MinVolatility);
    Print("Max Spread: ", Max_Spread, " USD");
    Print("TP: ", TakeProfitPips, " pips | SL: ", StopLossPips, " pips");
    Print("Lot Size: ", LotSize);
    if(UseMoneyManagement)
        Print("Money Management: ON (Risk ", RiskPercent, "%)");
    Print("Trading Hours: ", TradingStart, " - ", TradingEnd);
    
    // Info o Reverse Mode
    if(ReverseMode)
        Print("⚡ Reverse mode: ON – obrácená logika vstupů");
    else
        Print("✓ Reverse mode: OFF – standardní logika vstupů");
    
    Print("==============================================");
    
    Comment("TMA XAU Scalper v2 běží na ", _Symbol);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Uvolnění indikátorů
    if(rsi_handle != INVALID_HANDLE)
        IndicatorRelease(rsi_handle);
    if(atr_handle != INVALID_HANDLE)
        IndicatorRelease(atr_handle);
        Comment("EMA Pullback Scalper běží na ", _Symbol);
    Print("EMA Pullback Scalper ukončen");
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
    
    // Kontrola již otevřené pozice
    if(HasOpenPosition())
    {
        // Volitelně: kontrola exitových podmínek (návrat k TMA střední linii)
        CheckExitConditions();
        return;
    }
    
    // Kontrola obchodního času
    if(!IsTradingTime())
    {
        Print("⏰ Mimo obchodní hodiny");
        return;
    }
    
    // Kontrola spreadu
    double currentSpread = GetCurrentSpreadUSD();
    if(currentSpread > Max_Spread)
    {
        Print("📊 Spread příliš vysoký: ", DoubleToString(currentSpread, 2), " USD > ", Max_Spread, " USD");
        return;
    }
    
    // Získání indikátorových hodnot
    double rsi_value = GetRSI();
    double atr_value = GetATR();
    // Získání EMA hodnot
    double emaFast_buff[];
    double emaSlow_buff[];
    ArraySetAsSeries(emaFast_buff, true);
    ArraySetAsSeries(emaSlow_buff, true);
    if(CopyBuffer(emaFast_handle, 0, 0, 3, emaFast_buff) < 3 || CopyBuffer(emaSlow_handle, 0, 0, 3, emaSlow_buff) < 3)
    {
        Print("❌ Chyba při kopírování EMA bufferu");
        return;
    }
    // Pokud UseClosedBarEMA=true, bereme hodnotu z předchozího uzavřeného baru (index 1)
    double emaFast_curr = UseClosedBarEMA ? emaFast_buff[1] : emaFast_buff[0];
    double emaFast_prev = UseClosedBarEMA ? emaFast_buff[2] : emaFast_buff[1];
    double emaSlow_curr = UseClosedBarEMA ? emaSlow_buff[1] : emaSlow_buff[0];
    double emaSlow_prev = UseClosedBarEMA ? emaSlow_buff[2] : emaSlow_buff[1];
    
    if(emaFast_curr == 0.0 || emaSlow_curr == 0.0)
    {
        Print("❌ EMA hodnoty nejsou dostupné");
        return;
    }
    
    double close_price = iClose(_Symbol, PERIOD_CURRENT, 1);
    
    Print("=== ANALÝZA NOVÉHO BARU ===");
    Print("Close[1]: ", DoubleToString(close_price, 5));
    Print("EMA Fast: ", DoubleToString(emaFast_curr, 5), " | EMA Slow: ", DoubleToString(emaSlow_curr, 5));
    Print("RSI: ", DoubleToString(rsi_value, 2), " | ATR: ", DoubleToString(atr_value, 3), " | Spread: ", DoubleToString(currentSpread, 2), " USD");
    
    // Kontrola ATR filtru (minimální volatilita)
    if(atr_value < ATR_MinVolatility)
    {
        Print("⚠️ ATR příliš nízký (nízká volatilita): ", DoubleToString(atr_value, 3), " < ", ATR_MinVolatility);
        return;
    }
    
    // Logika vstupu podle ReverseMode
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    // Pro XAUUSD: 1 bod = 0.01 USD, takže PullbackTolerance v bodech → tolerance v ceně
    // Např: 1500 bodů * 0.01 = 15.00 USD distance
    double tolerance = PullbackTolerance * point;
    
    bool upTrend   = emaFast_curr > emaSlow_curr;      // definice trendu nahoru
    bool downTrend = emaFast_curr < emaSlow_curr;      // definice trendu dolů
    // S tolerancí: long pullback pokud cena <= emaSlow + tolerance
    bool pullbackLong  = (close_price <= emaSlow_curr + tolerance);
    // short pullback pokud cena >= emaSlow - tolerance
    bool pullbackShort = (close_price >= emaSlow_curr - tolerance);
    
    if(!ReverseMode)
    {
        // STANDARD: Pullback pokračující ve směru trendu
        bool buyCondition = upTrend && pullbackLong && (!UseRSIFilter || rsi_value < RSI_BuyLevel);
        bool sellCondition = downTrend && pullbackShort && (!UseRSIFilter || rsi_value > RSI_SellLevel);
        
        if(buyCondition)
        {
            Print("🟢 BUY SIGNÁL (Standard Pullback)");
            Print("   Trend UP (emaFast>emaSlow), cena v toleranci emaSlow");
            if(UseRSIFilter) Print("   RSI<", RSI_BuyLevel);
            OpenPosition(ORDER_TYPE_BUY, rsi_value, atr_value, currentSpread);
            return;
        }
        if(sellCondition)
        {
            Print("🔴 SELL SIGNÁL (Standard Pullback)");
            Print("   Trend DOWN (emaFast<emaSlow), cena v toleranci emaSlow");
            if(UseRSIFilter) Print("   RSI>", RSI_SellLevel);
            OpenPosition(ORDER_TYPE_SELL, rsi_value, atr_value, currentSpread);
            return;
        }
    }
    else
    {
        // REVERSE: Obchod proti trendu z extrému
        bool buyCondition = upTrend && pullbackShort && (!UseRSIFilter || rsi_value > RSI_SellLevel);
        bool sellCondition = downTrend && pullbackLong && (!UseRSIFilter || rsi_value < RSI_BuyLevel);
        
        if(buyCondition)
        {
            Print("🟢 BUY SIGNÁL (Reverse protitrend)");
            Print("   Trend UP, cena nad emaSlow (přepáleno)");
            if(UseRSIFilter) Print("   RSI>", RSI_SellLevel);
            OpenPosition(ORDER_TYPE_BUY, rsi_value, atr_value, currentSpread);
            return;
        }
        if(sellCondition)
        {
            Print("🔴 SELL SIGNÁL (Reverse protitrend)");
            Print("   Trend DOWN, cena pod emaSlow (přepáleno)");
            if(UseRSIFilter) Print("   RSI<", RSI_BuyLevel);
            OpenPosition(ORDER_TYPE_SELL, rsi_value, atr_value, currentSpread);
            return;
        }
    }
    
    if(DebugMode)
    {
        double distance = close_price - emaSlow_curr;
        string reasons="";
        if(!upTrend && !downTrend) reasons+="| Bez jasného trendu ";
        if(upTrend && !pullbackLong) reasons+=StringFormat("| Cena příliš nad emaSlow (dist=%.2f > tol=%.2f) ", distance, tolerance);
        if(downTrend && !pullbackShort) reasons+=StringFormat("| Cena příliš pod emaSlow (dist=%.2f < -tol=%.2f) ", distance, tolerance);
        if(UseRSIFilter && upTrend && pullbackLong && (rsi_value >= RSI_BuyLevel) && !ReverseMode) reasons+="| RSI není < BuyLevel ";
        if(UseRSIFilter && downTrend && pullbackShort && (rsi_value <= RSI_SellLevel) && !ReverseMode) reasons+="| RSI není > SellLevel ";
        if(ReverseMode && upTrend && !pullbackShort) reasons+="| Reverse BUY: cena není dost nad emaSlow ";
        if(UseRSIFilter && ReverseMode && upTrend && pullbackShort && !(rsi_value > RSI_SellLevel)) reasons+="| Reverse BUY: RSI není > SellLevel ";
        if(ReverseMode && downTrend && !pullbackLong) reasons+="| Reverse SELL: cena není dost pod emaSlow ";
        if(UseRSIFilter && ReverseMode && downTrend && pullbackLong && !(rsi_value < RSI_BuyLevel)) reasons+="| Reverse SELL: RSI není < BuyLevel ";
        string rsiStatus = UseRSIFilter ? StringFormat(" RSI=%.2f", rsi_value) : " RSI=OFF";
        Print("⚪ Žádný signál - upTrend=", upTrend, " downTrend=", downTrend, " close=", DoubleToString(close_price,5), " emaSlow=", DoubleToString(emaSlow_curr,5), " dist=", DoubleToString(distance,2), rsiStatus, " Důvody: ", reasons);
    } else {
        Print("⚪ Žádný signál - upTrend=", upTrend, " downTrend=", downTrend, " close=", DoubleToString(close_price,5), " emaSlow=", DoubleToString(emaSlow_curr,5), " RSI=", DoubleToString(rsi_value,2));
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
//| Kontrola obchodního času                                         |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Převod vstupních stringů na čas
    int start_hour, start_minute, end_hour, end_minute;
    
    if(StringSubstr(TradingStart, 2, 1) == ":")
    {
        start_hour = (int)StringToInteger(StringSubstr(TradingStart, 0, 2));
        start_minute = (int)StringToInteger(StringSubstr(TradingStart, 3, 2));
    }
    else
        return false;
    
    if(StringSubstr(TradingEnd, 2, 1) == ":")
    {
        end_hour = (int)StringToInteger(StringSubstr(TradingEnd, 0, 2));
        end_minute = (int)StringToInteger(StringSubstr(TradingEnd, 3, 2));
    }
    else
        return false;
    
    int current_time = dt.hour * 60 + dt.min;
    int start_time = start_hour * 60 + start_minute;
    int end_time = end_hour * 60 + end_minute;
    
    if(current_time >= start_time && current_time <= end_time)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Získání aktuálního spreadu v USD                                |
//+------------------------------------------------------------------+
double GetCurrentSpreadUSD()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spread = ask - bid;
    
    // Pro XAUUSD je spread přímo v USD (1 bod = 1 USD pro 1 lot)
    // Pro 0.10 lot to bude spread * 0.10
    return spread;
}

//+------------------------------------------------------------------+
//| Získání RSI hodnoty                                             |
//+------------------------------------------------------------------+
double GetRSI()
{
    double rsi[];
    ArraySetAsSeries(rsi, true);
    
    if(CopyBuffer(rsi_handle, 0, 0, 2, rsi) < 2)
    {
        Print("❌ Chyba při kopírování RSI bufferu");
        return -1;
    }
    
    return rsi[1]; // RSI předchozího uzavřeného baru
}

//+------------------------------------------------------------------+
//| Získání ATR hodnoty                                             |
//+------------------------------------------------------------------+
double GetATR()
{
    double atr[];
    ArraySetAsSeries(atr, true);
    
    if(CopyBuffer(atr_handle, 0, 0, 2, atr) < 2)
    {
        Print("❌ Chyba při kopírování ATR bufferu");
        return -1;
    }
    
    return atr[1]; // ATR předchozího uzavřeného baru
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Otevření pozice                                                  |
//+------------------------------------------------------------------+
void OpenPosition(ENUM_ORDER_TYPE orderType, double rsi_val, double atr_val, double spread_val)
{
    double price, sl = 0, tp = 0;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    // Výpočet lot size (pokud je zapnut Money Management)
    double lotSize = LotSize;
    if(UseMoneyManagement)
    {
        lotSize = CalculateLotSize();
    }
    
    // Normalizace lot size podle symbolu
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    
    Print("📊 Vypočtená velikost lotu: ", DoubleToString(lotSize, 2));
    
    // Nastavení ceny a SL/TP
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
    
    // Vytvoření objednávky
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lotSize;
    request.type = orderType;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.magic = MagicNumber;
    request.comment = TradeComment;
    request.deviation = 10;
    
    // Zjistit podporovaný filling mode
    int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
        request.type_filling = ORDER_FILLING_IOC;
    else if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
        request.type_filling = ORDER_FILLING_FOK;
    else
        request.type_filling = ORDER_FILLING_RETURN;
    
    // Log před odesláním
    Print("📤 Odesílám objednávku:");
    Print("   Type: ", EnumToString(orderType));
    Print("   Price: ", DoubleToString(price, digits));
    Print("   Volume: ", DoubleToString(lotSize, 2));
    Print("   SL: ", sl > 0 ? DoubleToString(sl, digits) : "Žádný");
    Print("   TP: ", tp > 0 ? DoubleToString(tp, digits) : "Žádný");
    Print("   RSI: ", DoubleToString(rsi_val, 2));
    Print("   ATR: ", DoubleToString(atr_val, 3));
    Print("   Spread: ", DoubleToString(spread_val, 2), " USD");
    
    bool orderResult = OrderSend(request, result);
    
    if(orderResult && result.retcode == TRADE_RETCODE_DONE)
    {
        Print("✅ Pozice otevřena úspěšně!");
        Print("   Ticket: #", result.order);
        Print("   ", EnumToString(orderType), " signal - RSI=", DoubleToString(rsi_val, 2), 
              ", ATR=", DoubleToString(atr_val, 3), ", Spread=", DoubleToString(spread_val, 2));
    }
    else
    {
        Print("❌ Chyba při otevírání pozice!");
        Print("   RetCode: ", result.retcode);
        Print("   Comment: ", result.comment);
    }
}

//+------------------------------------------------------------------+
//| Výpočet velikosti lotu podle Money Management                    |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (RiskPercent / 100.0);
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    
    // Pro XAUUSD: 1 pip = 10 bodů, SL v pipech
    double slPoints = StopLossPips * 10;
    
    // Výpočet: Risk Amount / (SL v bodech * Tick Value)
    double lotSize = 0;
    if(slPoints > 0 && tickValue > 0)
    {
        lotSize = riskAmount / (slPoints * tickValue / point);
    }
    else
    {
        lotSize = LotSize; // Fallback na fixní lot
    }
    
    return lotSize;
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
//| Kontrola exitových podmínek (volitelné)                         |
//+------------------------------------------------------------------+
void CheckExitConditions()
{
    // Volitelně: zavřít pozici při návratu ceny k TMA střední linii
    // Pro scalpování to může být předčasné, proto je tato funkce prázdná
    // Pozice se zavírají primárně přes SL/TP
    
    // Můžeš zde implementovat vlastní exit logiku, například:
    // - Trailing stop
    // - Break-even management
    // - Exit při návratu k TMA middle
}

//+------------------------------------------------------------------+
