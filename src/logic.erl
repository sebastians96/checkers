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
  IsJumpOver = checkIfRegularJump(Board, From, To),
  if
    (IsToAvailable == true) and (IsBlack == true) ->
      {Figure, Color} = getDraught(Board, From),
      BoardWithDeleted = deleteFromBoard(Board, From),
      BoardWithAdded = addToBoard(BoardWithDeleted, To, {Figure, Color}),
      BoardJumpOver = jumpIfOver(BoardWithAdded, From, To, Color, IsJumpOver),
      turnToKing(BoardJumpOver, To, Color);
    true -> throw(cannot_make_move_occupied)
  end.

addToBoard(Board, Pos, Draught) ->
  maps:put(Pos, Draught, Board).

deleteFromBoard(Board, Pos) ->
  maps:remove(Pos, Board).

jumpIfOver(Board, From, To, Color, IsOver) ->
  if
    IsOver == true -> killEnemyIfNecessary(Board, From, To, Color);
    true -> Board
  end.

%-- returns same board if no enemy between positions
%-- returns board without mid draught if enemy
killEnemyIfNecessary(Board, {Xfrom, Yfrom}, {Xto, Yto}, CurrentColor) ->
  EnemyPosition = {round((Xfrom + Xto) / 2), round((Yfrom + Yto) / 2)},
  IsEnemy = checkIfEnemy(Board, EnemyPosition, CurrentColor),
  if
    IsEnemy == true -> deleteFromBoard(Board, EnemyPosition);
    true -> Board
  end.

turnToKing(Board, Position, Color) ->
  TurnToKing = checkIfTurnsToKing(Position, Color),
  if
    TurnToKing == true -> maps:update(Position, {Color, king}, Board);
    true -> Board
  end.

%------------------------------- moves -------------------------------

%% discs can move one field forward (whites diagonally down,
%% blacks diagonally up), kings same for now...

%-- returns possible moves for figure from From position
getPossibleMoves(Board,Color) ->
  Filtered = maps:filter(fun(_,V) -> {ColorPiece,_} = V, ColorPiece == Color end,Board),
  MoveMap = maps:fold(fun(From,Piece,Acc) ->
              if Piece=={Color,disc} -> maps:put(From,getPossibleMoves(Board,From,{Color,disc}),Acc);
                 Piece=={Color,king} ->  maps:put(From,getPossibleMoves(Board,From,{Color,king}),Acc)
              end
            end,maps:new(),Filtered),
  MoveMap.

getPossibleMoves(Board, From = {X, Y}, {white, disc}) ->
  [{X1, Y1} || X1 <- [X + 1], Y1 <- [Y - 1, Y + 1], checkIfPosAvailable(Board, {X1, Y1})] ++
  [{X2, Y2} || X2 <- [X + 2], Y2 <- [Y - 2, Y + 2], checkIfPosAvailable(Board, {X2, Y2}), checkIfRegularJump(Board, From, {X2, Y2})];

getPossibleMoves(Board, From = {X, Y}, {black, disc}) ->
  [{X1, Y1} || X1 <- [X - 1], Y1 <- [Y - 1, Y + 1], checkIfPosAvailable(Board, {X1, Y1})] ++
  [{X2, Y2} || X2 <- [X - 2], Y2 <- [Y - 2, Y + 2], checkIfPosAvailable(Board, {X2, Y2}), checkIfRegularJump(Board, From, {X2, Y2})];

getPossibleMoves(Board, From = {X, Y}, {white, king}) ->
  [{X1, Y1} || X1 <- [X + 1], Y1 <- [Y - 1, Y + 1], checkIfPosAvailable(Board, {X1, Y1})] ++
  [{X2, Y2} || X2 <- [X + 2], Y2 <- [Y - 2, Y + 2], checkIfPosAvailable(Board, {X2, Y2}), checkIfRegularJump(Board, From, {X2, Y2})];

getPossibleMoves(Board, From = {X, Y}, {black, king}) ->
  [{X1, Y1} || X1 <- [X - 1], Y1 <- [Y - 1, Y + 1], checkIfPosAvailable(Board, {X1, Y1})] ++
  [{X2, Y2} || X2 <- [X - 2], Y2 <- [Y - 2, Y + 2], checkIfPosAvailable(Board, {X2, Y2}), checkIfRegularJump(Board, From, {X2, Y2})].

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

%-- returns true if there is sth between discs positions
checkIfRegularJump(Board, {Xfrom, Yfrom}, {Xto, Yto}) ->
  BetweenNotEmpty = checkIfOccupied(Board, {round((Xfrom + Xto) / 2), round((Yfrom + Yto) / 2)}),
  BetweenNotEmpty and ((Xfrom + Xto) rem 2 == 0) and ((Yfrom + Yto) rem 2 == 0).

checkIfTurnsToKing({X, _Y}, Color) ->
  ((X == 1) and (Color == black)) or
    ((X == 8) and (Color == white)).

%------------------------------ getters ------------------------------

getFieldType(Board, Position) ->
  maps:get(Position, Board, {getFieldColor(Position), field}).

getFieldColor({X, Y}) when (X + Y) rem 2 == 1 -> black;
getFieldColor({X, Y}) when (X + Y) rem 2 == 0 -> white;
getFieldColor(_) -> throw(exception_get_field_color).

getDraught(Board, Position) ->
  maps:get(Position, Board).
