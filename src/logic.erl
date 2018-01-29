%%%-------------------------------------------------------------------
%%% @author irmi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. sty 2018 11:41
%%%-------------------------------------------------------------------

-module(logic).
-author("irmi").

-include("constants.hrl").

%% API
-export([addToBoard/3, makeMove/3, getFieldType/2, getPossibleMoves/3, getPossibleMoves/2]).

%-------------------------- game logic -------------------------------

%-- returns board, position From is deleted
%-- and its draught with To position added, To must be black
%-- kills enemy if necessary
makeMove(Board, From, To) ->
  IsToAvailable = checkIfPosAvailable(Board, To),
  IsBlack = checkIfMoveFieldBlack(To),
  if
    (IsToAvailable == true) and (IsBlack == true) ->
      {Color, Figure} = getDraught(Board, From),
      IsJumpOver = checkIfRegularJump(Board, From, To, oppositeColor(Color)),
      BoardWithDeleted = deleteFromBoard(Board, From),
      BoardWithAdded = addToBoard(BoardWithDeleted, To, {Color, Figure}),
      BoardJumpOver = jumpIfOver(BoardWithAdded, From, To, IsJumpOver),
      turnToKing(BoardJumpOver, To, Color);
    true -> throw(cannot_make_move_occupied)
  end.

addToBoard(Board, Pos, Draught) ->
  maps:put(Pos, Draught, Board).

deleteFromBoard(Board, Pos) ->
  maps:remove(Pos, Board).

jumpIfOver(Board, {Xfrom, Yfrom}, {Xto, Yto}, IsOver) ->
  if
    IsOver == true ->
      Xenemy = round((Xfrom + Xto) / 2),
      Yenemy = round((Yfrom + Yto) / 2),
      EnemyPosition = {Xenemy, Yenemy},
      io:fwrite("{~w, ~w}", [Xenemy, Yenemy]),
      deleteFromBoard(Board, EnemyPosition);
    true -> Board
  end.

turnToKing(Board, Position, Color) ->
  TurnToKing = checkIfTurnsToKing(Position, Color),
  if
    TurnToKing == true -> maps:update(Position, {Color, king}, Board);
    true -> Board
  end.

%------------------------------- moves -------------------------------

getPossibleMoves(Board, Color) ->
  Filtered = maps:filter(fun(_, V) -> {ColorPiece, _} = V, ColorPiece == Color end, Board),
  JumpMap = maps:fold(fun(From, Piece, Acc) ->
    {Moves,HasJump} = getPossibleMoves(Board, From, Piece),
                          if HasJump==true ->
                              maps:put(From,Moves , Acc);
                              true -> Acc
                          end
                      end, maps:new(), Filtered),
  Size = maps:size(JumpMap),
  if Size==0 -> maps:fold(fun(From, Piece, Acc) ->
                          {Moves,_} = getPossibleMoves(Board, From, Piece),
                          maps:put(From,Moves, Acc)
                      end, maps:new(), Filtered);
    true -> JumpMap
end.

%% discs can move one field forward (whites diagonally down,
%% blacks diagonally up), kings same for now...
%% if there is a kill (jump) possible, then steps not generated
%-- returns possible moves for FigureType from From position
%% {Moves,HasJumps}
getPossibleMoves(Board, From, FigureType) ->
  Jumps = getJumps(Board, From, FigureType),
  NoKills = (Jumps == []),
  if
    NoKills == false ->
      {Jumps,true};
    NoKills == true ->
      {getSteps(Board, From, FigureType),false}
  end.

getJumps(Board, {X, Y}, {Color, disc}) ->
  [{X2, Y2} ||
    X2 <- [X - 2, X + 2], Y2 <- [Y - 2, Y + 2],
    checkIfPosAvailable(Board, {X2, Y2}),
    checkIfRegularJump(Board, {X, Y}, {X2, Y2}, oppositeColor(Color))];

getJumps(Board, {X, Y}, {Color, king}) ->
  [{X2, Y2} ||
    X2 <- [X - 2, X + 2], Y2 <- [Y - 2, Y + 2],
    checkIfPosAvailable(Board, {X2, Y2}),
    checkIfRegularJump(Board, {X, Y}, {X2, Y2}, oppositeColor(Color))].

getSteps(Board, {X, Y}, {white, disc}) ->
  [{X1, Y1} ||
    X1 <- [X + 1], Y1 <- [Y - 1, Y + 1],
    checkIfPosAvailable(Board, {X1, Y1})];

getSteps(Board, {X, Y}, {black, disc}) ->
  [{X1, Y1} ||
    X1 <- [X - 1], Y1 <- [Y - 1, Y + 1],
    checkIfPosAvailable(Board, {X1, Y1})];

getSteps(Board, {X, Y}, {_, king}) ->
  [{X1, Y1} ||
    X1 <- [X - 1, X + 1], Y1 <- [Y - 1, Y + 1],
    checkIfPosAvailable(Board, {X1, Y1})].

%------------------------------ checkers -----------------------------

checkIfPosAvailable(Board, Position = {X, Y}) ->
  Occupied = checkIfOccupied(Board, Position),
  if
    Occupied == false ->
      (X >= 1) and (X =< 8) and (Y =< 8) and (Y >= 1);
    true -> false
  end.

checkIfOccupied(Board, Position) ->
  maps:is_key(Position, Board).

checkIfEnemy(Board, EnemyPosition, CurrentColor) ->
  {Figure, Color} = getDraught(Board, EnemyPosition),
  IsDisc = Figure == disc,
  HasOppositeColor = Color /= CurrentColor,
  IsDisc and HasOppositeColor.

checkIfMoveFieldBlack(Position) ->
  Field = getFieldColor(Position),
  Field == black.

%-- returns true if there is enemy between positions
checkIfRegularJump(Board, {Xfrom, Yfrom}, {Xto, Yto}, EnemyColor) ->
  Xbetween = round((Xfrom + Xto) / 2),
  Ybetween = round((Yfrom + Yto) / 2),
  BetweenNotEmpty = checkIfOccupied(Board, {Xbetween, Ybetween}),
  {Color, _} = getFieldType(Board, {Xbetween, Ybetween}),
  (Color == EnemyColor) and BetweenNotEmpty and ((Xfrom + Xto) rem 2 == 0) and ((Yfrom + Yto) rem 2 == 0).

checkIfTurnsToKing({X, _Y}, white) -> X == 8;
checkIfTurnsToKing({X, _Y}, black) -> X == 1.

%------------------------------ getters ------------------------------

getFieldType(Board, Position) ->
  maps:get(Position, Board, {getFieldColor(Position), field}).

getFieldColor({X, Y}) when (X + Y) rem 2 == 1 -> black;
getFieldColor({X, Y}) when (X + Y) rem 2 == 0 -> white;
getFieldColor(_) -> throw(exception_get_field_color).

getDraught(Board, Position) ->
  maps:get(Position, Board).

%------------------------------ helpful ------------------------------

oppositeColor(white) -> black;
oppositeColor(black) -> white.