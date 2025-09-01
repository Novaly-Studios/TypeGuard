type UnitsReader = ((Buffer: buffer, Position: number) -> (number))
type FindMatch = ((StartLength: number, PositionA: number, PositionB: number) -> (number))

export type Matcher = {
    Initial: ((HistorySize: number, FutureSize: number, BufferLength: number, Read4: UnitsReader, FindMatch: FindMatch) -> ());
    Cleanup: (() -> ());
    Offset: ((Amount: number) -> ());
    Match: ((Buffer: buffer, Current: number) -> (number?, number?));
}

return {}