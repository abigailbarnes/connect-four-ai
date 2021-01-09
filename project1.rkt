#lang typed/racket
(require typed/test-engine/racket-tests)
(require "../include/cs151-core.rkt")
(require "../include/cs151-image.rkt")
(require "../include/cs151-universe.rkt")

;;Hi! Similar to lab 7, I had to comment out code for a lot of my
;;"eye-ball testing". My computer just keeps running out of memory or
;;the code takes ages to run, but rest assured... they are there!
;;all of the check-expects/withins/errors that correlate with values that
;;are outputted and are used in functions later on are left in
;;the only pieces of code i really had to comment out due to memory issues is
;;from the functions in the beginning that help me visualize the board!
;;of the "eye-ball tests" that i left in, the first is board-image and the rest
;;are for game-image with each direction of win being tested as well as
;;'tie and 'ongoing outcomes (as well as new game)!


;; We'll use the same version of Some and Optional that we used on Homework 5.
(define-struct (Some X)
  ([value : X]))

(define-type (Optional X)
  (U 'none (Some X)))

;; The game has two players, who we'll call 'black and 'white. You can choose
;; any color or pattern you would like for the pieces, but we'll still call
;; the players by these names.
(define-type Player (U 'black 'white))

;; (Pos row col) represents a position on the game board. The lower-left corner
;; is at row 0, column 0. The lower-right corner is at row 0, column 6. The
;; upper-left corner is at row 5, column 0. The upper-right corner is at row 5,
;; column 6.
(define-struct Pos
  ([row : Integer]   ;; integer between 0 and 5 inclusive
   [col : Integer])) ;; integer between 0 and 6 inclusive

;; (Stack height pieces) represents one full column of the game board. The
;; integer height is the number of pieces currently in that column. The
;; list pieces is a list of the pieces in the column (or more precisely, a list
;; of the players who placed the pieces). The last element of the list is the
;; bottom piece in the stack, while the first element of the list is the top
;; piece in the stack (so far). The value of height should alway match the
;; length of the list pieces.
(define-struct Stack
  ([height : Integer]
   [pieces : (Listof Player)]))

;; (Board stacks) represents a game board. The list stacks will always have
;; seven elements, representing the seven columns of the game board. The first
;; element of stacks represents the leftmost column of the board.
(define-struct Board
  ([stacks : (Listof Stack)]))

;; (Game board next) represents the state of the game at a given moment of time.
;; The current state of the game board is saved in board. The player whose turn
;; it is currently is stored in next.
(define-struct Game
  ([board : Board]
   [next : Player]))

;; If a player has won the game by creating a line of four, then
;; (Winning-Line player start end) can be used to keep track of which player
;; created the line of four, and where that line is (it goes from start to end).
;; Generally, if a player's winning move creates more than one line of four, we
;; won't care which one gets represented.
(define-struct Winning-Line
  ([player : Player]
   [start : Pos]
   [end : Pos]))





;;------------------------------DRAWING BOARD------------------------------
(: finish-column : Integer Integer -> Image)
;;finishes the stack drawing if the stack does not take up the whole column
;;
(define (finish-column stack-length space)
  (cond [(> (- 6 stack-length) 0)
         (above (overlay (circle (* 0.33 space) "solid" "gray")
                         (rectangle space space "solid" "black"))   
                (finish-column (+ stack-length 1) space))]
        [else empty-image]))

#|(finish-column 5 80)
(finish-column 0 80)
(finish-column 4 80)|#



(: spot-color : Player -> String)
;;takes in the player at which the piece/spot is associated
;;and returns a string correlating to the color of the piece
;;
(define (spot-color plyr)
  (match plyr
    ('black "blue")
    (_ "red")))

(check-expect (spot-color 'black) "blue")
(check-expect (spot-color 'white) "red")


(: colored-spot : (Listof Player) Integer -> Image)
;;draws the colored spots of the column
;;
(define (colored-spot lsts space)
  (match lsts
    ((cons lst lstr)
     (above
      (overlay
       (circle (* 0.33 space) "solid" (spot-color lst))
       (rectangle space space "solid" "black"))
      (colored-spot lstr space)))
    (_ empty-image)))



;;(colored-spot (list 'white 'black 'white 'black) 80)
;;(colored-spot (list 'white 'white 'white 'white) 80)
;;(colored-spot (list 'black) 80)


  

(: draw-stack : Stack Integer -> Image)
;;draws a single stack
;;note: stack list goes from top to bottom (beginning to end)
;;
(define (draw-stack stk space)
  (above (rectangle space (* 0.11 space) "solid" "black")
         (finish-column (Stack-height stk) space)
         (if (= (Stack-height stk) 0) empty-image 
             (colored-spot (Stack-pieces stk) space))
         (rectangle space (* 0.11 space) "solid" "black")))



#|(draw-stack (Stack 4 (list 'white 'black 'white 'black)) 80)
(draw-stack (Stack 7 (list 'white 'black 'black 'black 'white 'black 'white))
            80)
(draw-stack (Stack 0 '()) 80)|#



(: draw-playable-board : Board Integer -> Image)
;;draws the playable part of the board
;;
(define (draw-playable-board brds space)
  (match brds
    ((Board (cons brd brdr))
     (beside (draw-stack brd space)
             (draw-playable-board (Board brdr) space)))
    (_ empty-image)))


#|(draw-playable-board
 (Board
  (list
   (Stack 3 (list 'white 'black 'white))
   (Stack 1 (list 'black))
   (Stack 0 '())
   (Stack 0 '())
   (Stack 6 (list 'black 'white 'white 'white 'black 'white))
   (Stack 3 (list 'white 'black 'black))
   (Stack 0 '())))
 80)|#

(: draw-final-board : Board Integer -> Image)
;;draws board with appropriate spacing on the sides
;;
(define (draw-final-board brd space)
  (beside (rectangle (* 0.11 space)
                     (+ (* 6 space) (* 2 (* space 0.11)))
                     "solid" "black")
          (draw-playable-board brd space)
          (rectangle (* 0.11 space)
                     (+ (* 6 space)
                        (* 2 (* space 0.11)))
                     "solid" "black")))

#|(draw-final-board (Board
                  (list
                   (Stack 3 (list 'white 'black 'white))
                   (Stack 1 (list 'black))
                   (Stack 0 '())
                   (Stack 0 '())
                   (Stack 6 (list 'black 'white 'white 'white 'black 'white))
                   (Stack 3 (list 'white 'black 'black))
                   (Stack 0 '())))
                 80)|#

#|(draw-final-board (Board
                   (list
                    (Stack 0 '())
                    (Stack 0 '())
                    (Stack 0 '())
                    (Stack 0 '())
                    (Stack 0 '())
                    (Stack 0 '())
                    (Stack 0 '())))
                  80)|#


;;------------------------------PLAYING GAME------------------------------
(: new-game : Game)
;;starts a game where there are no pieces on the board and black
;;plays first
;;
(define new-game
  (Game
   (Board
    (list
     (Stack 0 '())
     (Stack 0 '())
     (Stack 0 '())
     (Stack 0 '())
     (Stack 0 '())
     (Stack 0 '())
     (Stack 0 '())))
   'black))
   
;;(draw-final-board (Game-board new-game) 80)
(check-expect (Game-next new-game) 'black)



;;------------------------------CIRCLES FUNCTS-------------------------------

(: center-circle-x : Integer Integer -> Real)
;;outputs the x coordinate for the center of the circle at
;;a given index
;;
(define (center-circle-x index space)
  (cond [(= 0 index)
         (+
          (* 0.11 space)
          (* 0.5 space))]
        [(= -1 index) -1]
        [else
         (+
          (* 0.11 space)
          (* 0.5 space)
          (* index space))]))

(check-within (center-circle-x 0 80) 48.8 0.001)
(check-within (center-circle-x 1 80) 128.8 0.001)
(check-within (center-circle-x 2 80) 208.8 0.001)
(check-within (center-circle-x 3 80) 288.8 0.001)
(check-within (center-circle-x 4 80) 368.8 0.001)
(check-within (center-circle-x 5 80) 448.8 0.001)
(check-within (center-circle-x 6 80) 528.8 0.001)
(check-expect (center-circle-x -1 80) -1)

(: center-circle-y : Integer Integer -> Real)
;;outputs the y-coordinate for the center of the circle
;;at a given index
;;
(define (center-circle-y index space)
  (+
   (* 0.11 space)
   (* 0.5 space)
   (* space (- 5 index))))

(check-within (center-circle-y 0 80) 448.8 0.001)
(check-within (center-circle-y 1 80) 368.8 0.001)
(check-within (center-circle-y 2 80) 288.8 0.001)
(check-within (center-circle-y 3 80) 208.8 0.001)
(check-within (center-circle-y 4 80) 128.8 0.001)
(check-within (center-circle-y 5 80) 48.8 0.001)



(: get-column : Integer Board -> Stack)
;;get the column correlating to the inputted integer
;;
(define (get-column index bs)
  (match (Board-stacks bs)
    ((cons b br)
     (cond [(= index 0) b]
           [else
            (get-column (- index 1) (Board br))]))
    (_ (Stack 0 '()))))

(check-expect (get-column 3 (Board
                             (list
                              (Stack 3 (list 'white 'black 'white))
                              (Stack 1 (list 'black))
                              (Stack 0 '())
                              (Stack 1 (list 'white))
                              (Stack 6 (list 'black 'white 'white 'white
                                             'black 'white))
                              (Stack 3 (list 'white 'black 'black))
                              (Stack 0 '())))) (Stack 1 (list 'white)))


(check-expect (get-column 0 (Board
                             (list
                              (Stack 3 (list 'white 'black 'white))
                              (Stack 1 (list 'black))
                              (Stack 0 '())
                              (Stack 0 '())
                              (Stack 6 (list 'black 'white 'white 'white
                                             'black 'white))
                              (Stack 3 (list 'white 'black 'black))
                              (Stack 0 '())))) (Stack 3 (list 'white
                                                              'black 'white)))

(check-expect (get-column 6 (Board
                             (list
                              (Stack 3 (list 'white 'black 'white))
                              (Stack 1 (list 'black))
                              (Stack 0 '())
                              (Stack 0 '())
                              (Stack 6 (list 'black 'white 'white 'white
                                             'black 'white))
                              (Stack 3 (list 'white 'black 'black))
                              (Stack 0 '())))) (Stack 0 '()))


(: get-row-element : Integer Stack -> Player)
;;returns the player color at the given element of the row,
;;if there is no player there, then return 'none
;;
(define (get-row-element index stks)
  (match (Stack-pieces stks)
    ((cons stk stkr)
     (cond [(= (- (- (Stack-height stks) 1) index) 0)
            stk]
           [else
            (get-row-element index (Stack (- (Stack-height stks) 1) stkr))]))
    (_ 'black)))



(check-expect (get-row-element 0
                               (Stack
                                3
                                (list
                                 'white
                                 'black
                                 'white))) 'white)

(check-expect (get-row-element 1
                               (Stack
                                3
                                (list
                                 'white
                                 'black
                                 'white))) 'black)

(check-expect (get-row-element 2
                               (Stack
                                3
                                (list
                                 'white
                                 'black
                                 'white))) 'white)


;;------------------------------BOARD-REF------------------------------
(: board-ref : Board Pos -> (Optional Player))
;;if there is a piece at that given clicked spot, return (Some Player)
;;or it returns none if there is not a piece there
;;NOTE: position is in format ROW,COLUMN
;;
(define (board-ref brd position)
  (cond
    [(or
      (= 6 (Pos-row position))
      (= 7 (Pos-col position)))
     (error "did not click circle")]
    [(<
      (-
       (Stack-height
        (get-column (Pos-col position) brd)) 1)
      (Pos-row position))
     'none]
    [(or
      (= -1 (Pos-row position))
      (= -1 (Pos-col position)))
     (error "did not click circle")]
    [(= (Stack-height
         (get-column (Pos-col position) brd)) 0)
     'none]
    [else
     (Some (get-row-element
            (Pos-row position)
            (get-column (Pos-col position) brd)))]))


(check-expect (board-ref
               (Board
                (list
                 (Stack 3 (list 'white 'black 'white))
                 (Stack 1 (list 'black))
                 (Stack 0 '())
                 (Stack 0 '())
                 (Stack 6 (list 'black 'white 'white 'white
                                'black 'white))
                 (Stack 3 (list 'white 'black 'black))
                 (Stack 0 '())))
               (Pos 5 6)) 'none)

(check-expect (board-ref
               (Board
                (list
                 (Stack 3 (list 'white 'black 'white))
                 (Stack 1 (list 'black))
                 (Stack 0 '())
                 (Stack 0 '())
                 (Stack 6 (list 'black 'white 'white 'white
                                'black 'white))
                 (Stack 3 (list 'white 'black 'black))
                 (Stack 0 '())))
               (Pos 5 4)) (Some 'black))

(check-expect (board-ref
               (Board
                (list
                 (Stack 3 (list 'white 'black 'white))
                 (Stack 1 (list 'black))
                 (Stack 0 '())
                 (Stack 0 '())
                 (Stack 6 (list 'black 'white 'white 'white
                                'black 'white))
                 (Stack 3 (list 'white 'black 'black))
                 (Stack 0 '())))
               (Pos 0 0)) (Some 'white))

(check-expect (board-ref
               (Board
                (list
                 (Stack 3 (list 'white 'black 'white))
                 (Stack 1 (list 'black))
                 (Stack 0 '())
                 (Stack 0 '())
                 (Stack 6 (list 'black 'white 'white 'white
                                'black 'white))
                 (Stack 3 (list 'white 'black 'black))
                 (Stack 0 '())))
               (Pos 4 3)) 'none)

(check-error (board-ref
              (Board
               (list
                (Stack 3 (list 'white 'black 'white))
                (Stack 1 (list 'black))
                (Stack 0 '())
                (Stack 0 '())
                (Stack 6 (list 'black 'white 'white 'white
                               'black 'white))
                (Stack 3 (list 'white 'black 'black))
                (Stack 0 '())))
              (Pos -1 -1)) "did not click circle")

(check-error (board-ref
              (Board
               (list
                (Stack 3 (list 'white 'black 'white))
                (Stack 1 (list 'black))
                (Stack 0 '())
                (Stack 0 '())
                (Stack 6 (list 'black 'white 'white 'white
                               'black 'white))
                (Stack 3 (list 'white 'black 'black))
                (Stack 0 '())))
              (Pos 6 2)) "did not click circle")


;;------------------------------VALID-MOVE------------------------------
(: valid-move? : Game Player Integer -> Boolean)
;;take in a game, player, and column number
;;if the columm number is valid and the column is not already full
;;return true
;;
(define (valid-move? gm plyr index)
  (and
   (not (= (Stack-height (get-column index (Game-board gm))) 6))
   (<= 0 index 6)
   (symbol=? (Game-next gm) plyr)))

(check-expect
 (valid-move?
  (Game
   (Board
    (list
     (Stack 3 (list 'white 'black 'white))
     (Stack 1 (list 'black))
     (Stack 0 '())
     (Stack 0 '())
     (Stack 6 (list 'black 'white 'white 'white
                    'black 'white))
     (Stack 3 (list 'white 'black 'black))
     (Stack 0 '())))
   'black)
  'black
  6)
 #t)

(check-expect (valid-move?
               (Game
                (Board
                 (list
                  (Stack 3 (list 'white 'black 'white))
                  (Stack 1 (list 'black))
                  (Stack 0 '())
                  (Stack 0 '())
                  (Stack 6 (list 'black 'white 'white 'white
                                 'black 'white))
                  (Stack 3 (list 'white 'black 'black))
                  (Stack 0 '())))
                'black)
               'black
               5)
              #t)
              
              

(check-expect (valid-move?
               (Game
                (Board
                 (list
                  (Stack 3 (list 'white 'black 'white))
                  (Stack 1 (list 'black))
                  (Stack 0 '())
                  (Stack 0 '())
                  (Stack 6 (list 'black 'white 'white 'white
                                 'black 'white))
                  (Stack 3 (list 'white 'black 'black))
                  (Stack 0 '())))
                'white)
               'black
               6)
              #f)


(check-expect (valid-move?
               (Game
                (Board
                 (list
                  (Stack 3 (list 'white 'black 'white))
                  (Stack 1 (list 'black))
                  (Stack 0 '())
                  (Stack 0 '())
                  (Stack 6 (list 'black 'white 'white 'white
                                 'black 'white))
                  (Stack 3 (list 'white 'black 'black))
                  (Stack 0 '())))
                'black)
               'black
               4)
              #f)

(check-expect (valid-move?
               (Game
                (Board
                 (list
                  (Stack 3 (list 'white 'black 'white))
                  (Stack 1 (list 'black))
                  (Stack 0 '())
                  (Stack 0 '())
                  (Stack 6 (list 'black 'white 'white 'white
                                 'black 'white))
                  (Stack 3 (list 'white 'black 'black))
                  (Stack 0 '())))
                'black)
               'black
               7)
              #f)

(check-expect (valid-move?
               (Game
                (Board
                 (list
                  (Stack 3 (list 'white 'black 'white))
                  (Stack 1 (list 'black))
                  (Stack 0 '())
                  (Stack 0 '())
                  (Stack 6 (list 'black 'white 'white 'white
                                 'black 'white))
                  (Stack 3 (list 'white 'black 'black))
                  (Stack 0 '())))
                'black)
               'black
               -1)
              #f)


(: index-map : All (X Y) (X Integer -> Y) (Listof X) -> (Listof Y))
;;applies function to the index of the map and the list inputted
;;
(define (index-map funct xs)
  (local
    {(: helper-index : All (X Y)
        (X Integer -> Y)
        (Listof X)
        Integer -> (Listof Y))
     ;;keeps track of the index for each val in the list
     ;;
     (define (helper-index function lsts position-tracker)
       (match lsts
         ((cons lst lstr) (cons (function lst position-tracker)
                                (helper-index function lstr
                                              (+ 1 position-tracker))))
         (_ '())))}
    (helper-index funct xs 0)))




(check-expect (index-map + (list 10 10 10 6 6)) (list 10 11 12 9 10))
(check-expect (index-map * (list 2 4 5 6)) (list 0 4 10 18))
(check-expect (index-map - (list 3 0 1 8)) (list 3 -1 -1 5))





(: list-length : All (X) (Listof X) Integer -> Integer)
;;finds the length of the inputted list
;;
(define (list-length lsts counter)
  (match lsts
    ((cons lst lstr) (list-length lstr (+ 1 counter)))
    (_ counter)))

(check-expect (list-length (list 1 2 4) 0) 3)
(check-expect (list-length (list 3 5 6 7 8) 0) 5)
(check-expect (list-length (list 2 3) 0) 2)

(: replace-at : All (A) Integer A (Listof A) -> (Listof A))
;; Replace the item at the given position i in the list xs with the new item x
;; position counting starts at 0
;;
;; ex: (replace-at 0 'Z (list 'a 'b 'c)) ---> (list 'Z 'b 'c)
;; ex: (replace-at 1 'Z (list 'a 'b 'c)) ---> (list 'a 'Z 'c)
;;
(define (replace-at i x xs)
  (if (> i (- (list-length xs 0) 1))
      xs 
      (local
        {(: helper-function : A Integer -> A)
         ;;function to input in index-map
         ;;
         (define (helper-function original-element ind)
           (if (= ind i)
               x
               original-element))}
        (if (> i (- (list-length xs 0) 1))
            xs
            (index-map helper-function xs)))))


(check-expect (replace-at 3 -50 (list 1 2 3 4 5)) (list 1 2 3 -50 5))
(check-expect (replace-at 7 2 (list 1 2 4)) (list 1 2 4))
(check-expect (replace-at 4 32 (list 11 10 56 39 27 94))
              (list 11 10 56 39 32 94))

(check-expect (replace-at 1 'Z (list 'a 'b 'c)) (list 'a 'Z 'c))


(: switch-player : Player -> Player)
;;input player and output the other player
;;changed turn of game board
;;
(define (switch-player plyr)
  (match plyr
    ('white 'black)
    (_ 'white)))

(check-expect (switch-player 'white) 'black)
(check-expect (switch-player 'black) 'white)

;;-------------------------------APPLY-MOVE-------------------------------
(: apply-move : Game Player Integer -> Game)
;;applies the proposed move to the game board, updates the player who's turn it
;;is and outputs the updated Game... if the move is invalid return an error
;;
(define (apply-move gm plyr index)
  (cond [(valid-move? gm plyr index)
         (Game
          (Board
           (replace-at
            index 
            (Stack (+ 1 (Stack-height
                         (get-column index (Game-board gm))))
                   (cons plyr
                         (Stack-pieces (get-column index
                                                   (Game-board gm)))))
            (Board-stacks (Game-board gm))))
          (switch-player (Game-next gm)))]
        [else (error "proposed move is illegal")]))


(check-expect
 (apply-move
  (Game
   (Board
    (list
     (Stack 3 (list 'white 'black 'white))
     (Stack 1 (list 'black))
     (Stack 0 '())
     (Stack 0 '())
     (Stack 6 (list 'black 'white 'white 'white
                    'black 'white))
     (Stack 3 (list 'white 'black 'black))
     (Stack 0 '())))
   'black)
  'black
  0)
 (Game
  (Board
   (list
    (Stack 4 (list 'black 'white 'black 'white))
    (Stack 1 (list 'black))
    (Stack 0 '())
    (Stack 0 '())
    (Stack 6 (list 'black 'white 'white 'white
                   'black 'white))
    (Stack 3 (list 'white 'black 'black))
    (Stack 0 '())))
  'white))


(check-expect
 (apply-move
  (Game
   (Board
    (list
     (Stack 3 (list 'white 'black 'white))
     (Stack 1 (list 'black))
     (Stack 0 '())
     (Stack 0 '())
     (Stack 6 (list 'black 'white 'white 'white
                    'black 'white))
     (Stack 3 (list 'white 'black 'black))
     (Stack 0 '())))
   'black)
  'black
  2)
 (Game
  (Board
   (list
    (Stack 3 (list 'white 'black 'white))
    (Stack 1 (list 'black))
    (Stack 1 (list 'black))
    (Stack 0 '())
    (Stack 6 (list 'black 'white 'white 'white
                   'black 'white))
    (Stack 3 (list 'white 'black 'black))
    (Stack 0 '())))
  'white))

(check-error
 (apply-move
  (Game
   (Board
    (list
     (Stack 3 (list 'white 'black 'white))
     (Stack 1 (list 'black))
     (Stack 0 '())
     (Stack 0 '())
     (Stack 6 (list 'black 'white 'white 'white
                    'black 'white))
     (Stack 3 (list 'white 'black 'black))
     (Stack 0 '())))
   'black)
  'black
  4)
 "proposed move is illegal")



;;------------------------------DIRECTION------------------------------
;;Direction will be the direction to search for/label the "wins"
;;Name, Change in x position - column , Change in y position - row
;;
(define-struct Direction
  ([d : String]
   [dx : Integer]
   [dy : Integer]))



(: make-direction : Integer -> Direction)
;;outputs a direction object according to an integer
;;checks vertical, horizontal, diagonal positive, diagonal negative
;;
(define (make-direction counter)
  (match counter
    (0 (Direction "vertical" 0 -1))
    (1 (Direction "horizontal" 1 0))
    (2 (Direction "diagonal-positive" 1 1))
    (3 (Direction "diagonal-negative" 1 -1))
    (4 (Direction "N/A" 0 0))
    (_ (error "inputted value not allowed"))))

(check-expect (make-direction 0) (Direction "vertical" 0 -1))
(check-expect (make-direction 1) (Direction "horizontal" 1 0))
(check-expect (make-direction 2) (Direction "diagonal-positive" 1 1))
(check-expect (make-direction 3) (Direction "diagonal-negative" 1 -1))
(check-error (make-direction 8) "inputted value not allowed")




(: board-ref-player? : Board Pos -> Integer)
;;returns an integer representing the state of board-ref
;;
(define (board-ref-player? brd position)
  (match (board-ref brd position)
    ((Some 'black) 1)
    ((Some 'white) 2)
    (_ 0)))

(check-expect (board-ref-player?
               (Board
                (list
                 (Stack 3 (list 'white 'black 'white))
                 (Stack 1 (list 'black))
                 (Stack 1 (list 'black))
                 (Stack 0 '())
                 (Stack 6 (list 'black 'white 'white 'white
                                'black 'white))
                 (Stack 3 (list 'white 'black 'black))
                 (Stack 0 '())))
               (Pos 3 3)) 0)

(check-expect (board-ref-player?
               (Board
                (list
                 (Stack 3 (list 'white 'black 'white))
                 (Stack 1 (list 'black))
                 (Stack 1 (list 'black))
                 (Stack 0 '())
                 (Stack 6 (list 'black 'white 'white 'white
                                'black 'white))
                 (Stack 3 (list 'white 'black 'black))
                 (Stack 0 '())))
               (Pos 0 1)) 1)

(check-expect (board-ref-player?
               (Board
                (list
                 (Stack 3 (list 'white 'black 'white))
                 (Stack 1 (list 'black))
                 (Stack 1 (list 'black))
                 (Stack 0 '())
                 (Stack 6 (list 'black 'white 'white 'white
                                'black 'white))
                 (Stack 3 (list 'white 'black 'black))
                 (Stack 0 '())))
               (Pos 2 5)) 2) 




(: player-to-integer : Player -> Integer)
;;converts player into an integer value to compare against board-ref
;;
(define (player-to-integer plyr)
  (match plyr
    ('black 1)
    (_ 2)))


(check-expect (player-to-integer 'black) 1)
(check-expect (player-to-integer 'white) 2)



(: movement-counter : Game Pos Integer Integer Integer -> Integer)
;;takes in the elements to move in a particular direction designated by string
;;and returns the total number of elements in a line in that given direction
;;dx and dy are taken from the Direction that is inputted in line-of-four?
;;NOTE: POSITION WILL ALWAYS BE THE TOP OF THE GIVEN STACK, STACK-HEIGHT - 1
;;
(define (movement-counter gm position dx dy counter)
  (cond [(= counter 3) counter]
        [(or
          (= -1 (+ dy (Pos-row position)))
          (= -1 (+ dx (Pos-col position)))
          (= 6 (+ dy (Pos-row position)))
          (= 7 (+ dx (Pos-col position)))) counter]
        [(=
          (board-ref-player? (Game-board gm)
                             position)
          (board-ref-player? (Game-board gm)
                             (Pos
                              (+ dy (Pos-row position))
                              (+ dx (Pos-col position)))))
         (movement-counter gm
                           (Pos
                            (+ dy (Pos-row position))
                            (+ dx (Pos-col position)))
                           dx
                           dy
                           (+ 1 counter))]
        [else counter]))


(check-expect (movement-counter
               (Game
                (Board
                 (list
                  (Stack 6 (list 'white 'white 'white 'white 'black 'black))
                  (Stack 5 (list 'black 'black 'black 'white 'white))
                  (Stack 2 (list 'white 'white))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'white 'white))))
                'black)
               (Pos 5 0)
               0
               -1
               0) 3)

(check-expect (movement-counter
               (Game
                (Board
                 (list
                  (Stack 6 (list 'white 'white 'white 'black 'black 'black))
                  (Stack 5 (list 'black 'black 'black 'white 'white))
                  (Stack 2 (list 'white 'white))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'white 'white))))
                'black)
               (Pos 5 0)
               0
               -1
               0) 2)

(check-expect (movement-counter
               (Game
                (Board
                 (list
                  (Stack 5 (list 'white 'black 'black 'white 'white))
                  (Stack 4 (list 'white 'black 'black 'black))
                  (Stack 3 (list 'white 'black 'white))
                  (Stack 2 (list 'white 'white))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'white 'white))))
                'black)
               (Pos 4 0)
               1
               -1
               0) 3)

(check-expect (movement-counter
               (Game
                (Board
                 (list
                  (Stack 1 (list 'white))
                  (Stack 1 (list 'white))
                  (Stack 1 (list 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 3 (list 'black 'white 'black))
                  (Stack 4 (list 'black 'white 'black 'white))
                  (Stack 5 (list 'white 'white 'white 'black 'white))))
                'black)
               (Pos 0 2)
               1
               1
               0) 3)
  


(: line-of-four? : Game Pos Direction -> Boolean)
;;checks to see if there is a line of four in any given direction
;;
(define (line-of-four? gm position dir)
  (<= 3
      (+
       (movement-counter gm
                         position
                         (Direction-dx dir)
                         (Direction-dy dir)
                         0)
       (movement-counter gm
                         position
                         (- 0 (Direction-dx dir))
                         (- 0 (Direction-dy dir))
                         0))))


(check-expect (line-of-four?
               (Game
                (Board
                 (list
                  (Stack 4 (list 'white 'black 'black 'white))
                  (Stack 3 (list 'white 'black 'white))
                  (Stack 2 (list 'white 'black))
                  (Stack 1 (list 'white))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'black))))
                'black)
               (Pos 2 1)
               (Direction "vertical" 0 -1)) #f)

(check-expect
 (line-of-four?
  (Game
   (Board
    (list
     (Stack 4 (list 'white 'black 'black 'white))
     (Stack 3 (list 'white 'black 'white))
     (Stack 2 (list 'white 'black))
     (Stack 1 (list 'white))
     (Stack 1 (list 'black))
     (Stack 1 (list 'black))
     (Stack 1 (list 'black))))
   'black)
  (Pos 2 1)
  (Direction "diagonal-negative" 1 -1)) #t)


(check-expect
 (line-of-four?
  (Game
   (Board
    (list
     (Stack 5 (list 'white 'black 'black 'white 'white))
     (Stack 3 (list 'black 'black 'black))
     (Stack 3 (list 'white 'white 'white))
     (Stack 3 (list 'white 'white 'black))
     (Stack 4 (list 'black 'white 'black 'white))
     (Stack 5 (list 'white 'black 'white 'black 'white))
     (Stack 6 (list 'black 'white 'black 'black 'white 'white))))
   'black)
  (Pos 2 3)
  (Direction "diagonal-positive" 1 1)) #f)

(check-expect
 (line-of-four?
  (Game
   (Board
    (list
     (Stack 5 (list 'white 'black 'black 'white 'white))
     (Stack 3 (list 'black 'black 'black))
     (Stack 3 (list 'white 'white 'white))
     (Stack 3 (list 'white 'white 'black))
     (Stack 4 (list 'black 'white 'black 'white))
     (Stack 5 (list 'white 'black 'white 'black 'white))
     (Stack 6 (list 'black 'white 'black 'black 'white 'white))))
   'black)
  (Pos 2 3)
  (Direction "horizontal" 1 0)) #t)


(check-expect
 (line-of-four?
  (Game
   (Board
    (list
     (Stack 5 (list 'white 'black 'black 'white 'white))
     (Stack 3 (list 'black 'black 'black))
     (Stack 3 (list 'black 'white 'white))
     (Stack 3 (list 'white 'white 'black))
     (Stack 4 (list 'black 'white 'black 'white))
     (Stack 4 (list 'white 'white 'black 'white))
     (Stack 6 (list 'black 'white 'black 'black 'white 'white))))
   'black)
  (Pos 3 5)
  (Direction "diagonal-positive" 1 1)) #t)




(: check-all-direction : Game Pos Integer -> Direction)
;;checks all directions about a given point, returns string dictating
;;the direction in which the line of four happened
;;if a line of four never happens return an empty list
;;
(define (check-all-direction gm position counter)
  (cond [(and
          (< counter 4)
          (not (line-of-four? gm position (make-direction counter))))
         (check-all-direction gm position (+ 1 counter))]
        [(and
          (< counter 4)
          (line-of-four? gm position (make-direction counter)))
         (make-direction counter)]
        [else (Direction "N/A" 0 0)]))

(check-expect (check-all-direction
               (Game
                (Board
                 (list
                  (Stack 5 (list 'white 'black 'black 'white 'white))
                  (Stack 3 (list 'black 'black 'black))
                  (Stack 3 (list 'white 'white 'white))
                  (Stack 3 (list 'white 'white 'black))
                  (Stack 4 (list 'black 'white 'black 'white))
                  (Stack 5 (list 'white 'black 'white 'black 'white))
                  (Stack 6 (list 'black 'white 'black 'black 'white 'white))))
                'black)
               (Pos 2 3)
               0) (Direction "horizontal" 1 0))

(check-expect (check-all-direction
               (Game
                (Board
                 (list
                  (Stack 5 (list 'white 'black 'black 'white 'white))
                  (Stack 3 (list 'black 'black 'black))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 3 (list 'white 'white 'black))
                  (Stack 4 (list 'black 'white 'black 'white))
                  (Stack 4 (list 'white 'white 'black 'white))
                  (Stack 6 (list 'black 'white 'black 'black 'white 'white))))
                'black)
               (Pos 3 5)
               0) (Direction "diagonal-positive" 1 1))

(check-expect (check-all-direction
               (Game
                (Board
                 (list
                  (Stack 6 (list 'white 'black 'black 'black 'white 'white))
                  (Stack 4 (list 'black 'black 'black 'white))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 3 (list 'white 'black 'black))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 1 (list 'white))))
                'black)
               (Pos 2 2)
               0) (Direction "diagonal-negative" 1 -1))

(check-expect (check-all-direction
               (Game
                (Board
                 (list
                  (Stack 5 (list 'black 'black 'black 'white 'white))
                  (Stack 5 (list 'black 'black' black 'black 'white))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 3 (list 'white 'white 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 0 '())
                  (Stack 0 '())))
                'black)
               (Pos 4 1)
               0) (Direction "vertical" 0 -1))

(: calculate-position-winning-beginning : Game Pos Direction -> Pos)
;;takes in elements, and outputs the beginning position of the line of four
;;
(define (calculate-position-winning-beginning gm position dir)
  (cond
    [(or
      (= -1 (- (Pos-row position) (Direction-dy dir)))
      (= -1 (- (Pos-col position) (Direction-dx dir)))
      (= 6 (- (Pos-row position) (Direction-dy dir)))
      (= 7 (- (Pos-col position) (Direction-dx dir))))
     position]
    [(=
      (board-ref-player? (Game-board gm) position)
      (board-ref-player? (Game-board gm)
                         (Pos
                          (- (Pos-row position) (Direction-dy dir))
                          (- (Pos-col position) (Direction-dx dir)))))
     (calculate-position-winning-beginning
      gm
      (Pos
       (- (Pos-row position)
          (Direction-dy dir))
       (- (Pos-col position)
          (Direction-dx dir)))
      dir)]
    [else position]))



(check-expect (calculate-position-winning-beginning
               (Game
                (Board
                 (list
                  (Stack 5 (list 'black 'black 'black 'white 'white))
                  (Stack 5 (list 'black 'black' black 'black 'white))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 3 (list 'white 'white 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 0 '())
                  (Stack 0 '())))
                'black)
               (Pos 4 1)
               (Direction "vertical" 0 -1)) (Pos 4 1))


(check-expect (calculate-position-winning-beginning
               (Game
                (Board
                 (list
                  (Stack 5 (list 'white 'black 'black 'white 'white))
                  (Stack 3 (list 'black 'black 'black))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 3 (list 'white 'white 'black))
                  (Stack 4 (list 'black 'white 'black 'white))
                  (Stack 4 (list 'white 'white 'black 'white))
                  (Stack 6 (list 'black 'white 'black 'black 'white 'white))))
                'black)
               (Pos 3 5)
               (Direction "diagonal-positive" 1 1)) (Pos 0 2))


(: calculate-position-winning-end : Game Pos Direction -> Pos)
;;takes in elements, and outputs the beginning position of the line of four
;;
(define (calculate-position-winning-end gm position dir)
  (cond
    [(or
      (= -1 (+ (Pos-row position) (Direction-dy dir)))
      (= -1 (+ (Pos-col position) (Direction-dx dir)))
      (= 6 (+ (Pos-row position) (Direction-dy dir)))
      (= 7 (+ (Pos-col position) (Direction-dx dir))))
     position]
    [(=
      (board-ref-player? (Game-board gm) position)
      (board-ref-player? (Game-board gm)
                         (Pos
                          (+ (Pos-row position) (Direction-dy dir))
                          (+ (Pos-col position) (Direction-dx dir)))))
     (calculate-position-winning-end
      gm
      (Pos
       (+ (Pos-row position)
          (Direction-dy dir))
       (+ (Pos-col position)
          (Direction-dx dir)))
      dir)]
    [else position]))



(check-expect (calculate-position-winning-end
               (Game
                (Board
                 (list
                  (Stack 5 (list 'black 'black 'black 'white 'white))
                  (Stack 5 (list 'black 'black' black 'black 'white))
                  (Stack 3 (list 'black 'white 'white))
                  (Stack 3 (list 'white 'white 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 0 '())
                  (Stack 0 '())))
                'black)
               (Pos 4 1)
               (Direction "vertical" 0 -1)) (Pos 1 1))

(check-expect (calculate-position-winning-end
               (Game
                (Board
                 (list
                  (Stack 5 (list 'white 'white 'black 'white 'black))
                  (Stack 5 (list 'white 'black 'white 'black 'white))
                  (Stack 4 (list 'black 'white 'black 'white))
                  (Stack 3 (list 'black 'black 'white))
                  (Stack 1 (list 'white))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'white))))
                'black)
               (Pos 0 2)
               (Direction "horizontal" 1 0)) (Pos 0 4))

(check-expect (calculate-position-winning-end
               (Game
                (Board
                 (list
                  (Stack 1 (list 'black))
                  (Stack 2 (list 'black 'white))
                  (Stack 3 (list 'black 'white 'black))
                  (Stack 4 (list 'black 'black 'white 'black))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'white))
                  (Stack 1 (list 'black))))
                'white)
               (Pos 1 1)
               (Direction "diagonal-positive" 1 1)) (Pos 3 3))


(check-expect (calculate-position-winning-end
               (Game
                (Board
                 (list
                  (Stack 1 (list 'black))
                  (Stack 2 (list 'black 'white))
                  (Stack 3 (list 'black 'white 'black))
                  (Stack 4 (list 'black 'black 'white 'black))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'white))
                  (Stack 1 (list 'black))))
                'white)
               (Pos 2 3)
               (Direction "diagonal-negative" 1 -1)) (Pos 2 3))






(: full-board? : Board -> Boolean)
;;returns true if the board is full
;;
(define (full-board? brds)
  (match (Board-stacks brds)
    ((cons stk stkr)
     (and (= (Stack-height stk) 6)
          (full-board? (Board stkr))))
    (_ #t)))


(check-expect (full-board?
               (Board
                (list
                 (Stack 6 (list 'white 'black 'black 'white 'white 'white))
                 (Stack 6 (list 'black 'black 'black 'white 'white 'black))
                 (Stack 6 (list 'black 'white 'white 'black 'white 'black))
                 (Stack 6 (list 'white 'white 'black 'white 'black 'white))
                 (Stack 6 (list 'black 'white 'black 'white 'white 'black))
                 (Stack 6 (list 'white 'white 'black 'white 'black 'black))
                 (Stack 6 (list 'black 'white 'black 'black 'white 'white)))))
              #t)

(check-expect (full-board?
               (Board
                (list
                 (Stack 5 (list 'white 'black 'black 'white 'white))
                 (Stack 3 (list 'black 'black 'black))
                 (Stack 3 (list 'black 'white 'white))
                 (Stack 3 (list 'white 'white 'black))
                 (Stack 4 (list 'black 'white 'black 'white))
                 (Stack 4 (list 'white 'white 'black 'white))
                 (Stack 6 (list 'black 'white 'black 'black 'white 'white)))))
              #f)


            
    


(: checking-stack-tops : Game Integer -> Pos)
;;loops through the tops piece of each stack, if part of a winning line
;;returns the position of the piece, else it keeps looping through
;;will return Pos -1 -1 if the board has no matches
;;
(define (checking-stack-tops gm col)
  (cond
    [(> col 7) (Pos -1 -1)]
    [(or
      (= col 7)
      (= 6 (- (Stack-height
               (get-column col
                           (Game-board gm))) 1))
      (= -1 (- (Stack-height
                (get-column col
                            (Game-board gm))) 1))
      (= -1 col))
     (checking-stack-tops gm (+ 1 col))]
    [(and
      (= 0
         (Direction-dx
          (check-all-direction gm
                               (Pos (- (Stack-height
                                        (get-column col
                                                    (Game-board gm))) 1) col)
                               0)))
      (= 0
         (Direction-dy
          (check-all-direction gm
                               (Pos (- (Stack-height
                                        (get-column col
                                                    (Game-board gm))) 1) col)
                               0))))
     (checking-stack-tops gm (+ 1 col))]     
    [else
     (Pos (- (Stack-height (get-column col (Game-board gm))) 1) col)]))

 


(check-expect (checking-stack-tops
               (Game
                (Board
                 (list
                  (Stack 6 (list 'white 'white 'white 'white 'black 'black))
                  (Stack 5 (list 'black 'black 'black 'white 'white))
                  (Stack 4 (list 'black 'black 'black 'white))
                  (Stack 3 (list 'white 'white 'white))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'black))))
                'black) 0) (Pos 5 0))

(check-expect (checking-stack-tops
               (Game
                (Board
                 (list
                  (Stack 5 (list 'white 'white 'white 'black 'black))
                  (Stack 5 (list 'black 'black 'black 'black 'white))
                  (Stack 4 (list 'black 'black 'black 'white))
                  (Stack 3 (list 'white 'white 'white))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'black))
                  (Stack 1 (list 'black))))
                'black) 0) (Pos 4 1))

(check-expect (checking-stack-tops
               (Game
                (Board
                 (list
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'white 'black))
                  (Stack 2 (list 'black 'black))
                  (Stack 2 (list 'black 'white))
                  (Stack 2 (list 'white 'white))
                  (Stack 2 (list 'white 'white))
                  (Stack 2 (list 'black 'black))))
                'black) 0) (Pos -1 -1))
    
            



(: outcome : Game -> (U Winning-Line 'tie 'ongoing))
;;if one player has a line of four, output a winning-line
;;if there are no more moves and no one has a winning-line, 'tie
;;else the game is ongoing
;;
(define (outcome gm)
  (cond
    [(and
      (full-board? (Game-board gm))
      (and
       (= -1 (Pos-row (checking-stack-tops gm 0)))
       (= -1 (Pos-col (checking-stack-tops gm 0)))))
     'tie]
    [(and (= -1 (Pos-row (checking-stack-tops gm 0)))
          (= -1 (Pos-col (checking-stack-tops gm 0))))
     'ongoing]
    [else
     (Winning-Line
      (switch-player (Game-next gm))
      (calculate-position-winning-beginning
       gm
       (checking-stack-tops gm 0)
       (check-all-direction gm
                            (checking-stack-tops gm 0)
                            0))
      (calculate-position-winning-end
       gm
       (checking-stack-tops gm 0)
       (check-all-direction gm
                            (checking-stack-tops gm 0)
                            0)))]))


                
(check-expect (outcome (Game
                        (Board
                         (list
                          (Stack 5 (list 'white 'white 'white 'black 'black))
                          (Stack 5 (list 'black 'black 'black 'black 'white))
                          (Stack 4 (list 'black 'black 'black 'white))
                          (Stack 3 (list 'white 'white 'white))
                          (Stack 1 (list 'black))
                          (Stack 1 (list 'black))
                          (Stack 1 (list 'black))))
                        'white)) (Winning-Line 'black (Pos 4 1) (Pos 1 1)))

(check-expect
 (outcome (Game
           (Board
            (list
             (Stack 1 (list 'black))
             (Stack 0 '())
             (Stack 0 '())
             (Stack 0 '())
             (Stack 0 '())
             (Stack 0 '())
             (Stack 0 '())))
           'white)) 'ongoing)




;;-------------------------------BOARD-IMAGE-------------------------------
(: board-image : Board Integer -> Image)
;;prints the current state of the board
;;with integer spacing
;;
(define (board-image brd space)
  (draw-final-board brd space))


(board-image (Board
              (list
               (Stack 5 (list 'white 'white 'white 'black 'black))
               (Stack 5 (list 'black 'black 'black 'black 'white))
               (Stack 4 (list 'black 'black 'black 'white))
               (Stack 3 (list 'white 'white 'white))
               (Stack 1 (list 'black))
               (Stack 1 (list 'black))
               (Stack 1 (list 'black))))
             80)



(: player-turn-string : Player -> String)
;;takes in a Player and returns a string indicating it is their turn
;;
(define (player-turn-string plyr)
  (match plyr
    ('black "It is Player 1's turn!")
    (_ "It is Player 2's turn!")))

(check-expect (player-turn-string 'black) "It is Player 1's turn!")
(check-expect (player-turn-string 'white) "It is Player 2's turn!")


(: player-winning-string : Player -> String)
;;takes in a Player and returns a string indicating it is their turn
;;
(define (player-winning-string plyr)
  (match plyr
    ('black "Player 2 won this game!")
    (_ "Player 1 won this game!")))

(check-expect (player-winning-string 'black) "Player 2 won this game!")
(check-expect (player-winning-string 'white) "Player 1 won this game!")



;;-------------------------------GAME-IMAGE-------------------------------
(: game-image : Game Integer -> Image)
;;says who's turn it is if the game is on going
;;if outcome returns winning line, draw the line from beginnnig pos
;;to end pos and print the name of the winner
;;if a tie, print "game is a tie" and the plain board
;;
(define (game-image gm space)
  (match (outcome gm)
    ('ongoing
     (above
      (board-image (Game-board gm) space)
      (overlay (text (player-turn-string (Game-next gm)) 20 "black")
               (rectangle (+ (* 0.11 2 space)
                             (* space 7))
                          space
                          "outline"
                          "black"))))
    ('tie
     (above
      (board-image (Game-board gm) space)
      (overlay (text "The game tied!" 20 "black")
               (rectangle (+ (* 0.11 2 space)
                             (* space 7))
                          space
                          "outline"
                          "black"))))
    ((Winning-Line winner (Pos row1 col1) (Pos row2 col2))
     (above
      (add-line
       (board-image (Game-board gm) space)
       (center-circle-x col1 space)
       (center-circle-y row1 space)
       (center-circle-x col2 space)
       (center-circle-y row2 space)
       "yellow")
      (overlay (text (player-winning-string (Game-next gm))
                     20
                     "black")
               (rectangle (+ (* 0.11 2 space)
                             (* space 7))
                          space
                          "outline"
                          "black"))))))

;;verticle
(game-image
 (Game
  (Board
   (list
    (Stack 5 (list 'white 'white 'white 'black 'black))
    (Stack 5 (list 'black 'black 'black 'black 'white))
    (Stack 4 (list 'black 'black 'black 'white))
    (Stack 3 (list 'white 'white 'white))
    (Stack 1 (list 'black))
    (Stack 1 (list 'black))
    (Stack 1 (list 'black))))
  'white) 80)

;;horizontal
(game-image
 (Game
  (Board
   (list
    (Stack 5 (list 'white 'white 'black 'white 'black))
    (Stack 5 (list 'white 'black 'white 'black 'white))
    (Stack 4 (list 'black 'white 'black 'white))
    (Stack 3 (list 'black 'black 'white))
    (Stack 1 (list 'white))
    (Stack 1 (list 'black))
    (Stack 1 (list 'white))))
  'black) 80)

;;diagonal-positive
(game-image
 (Game
  (Board
   (list
    (Stack 1 (list 'black))
    (Stack 2 (list 'black 'white))
    (Stack 3 (list 'black 'white 'black))
    (Stack 4 (list 'black 'black 'white 'black))
    (Stack 1 (list 'black))
    (Stack 1 (list 'white))
    (Stack 1 (list 'black))))
  'white) 80)

;;diagonal-negative
(game-image
 (Game
  (Board
   (list
    (Stack 6 (list 'white 'white 'white 'black 'black 'black))
    (Stack 5 (list 'white 'black 'black 'black 'white))
    (Stack 4 (list 'white 'black 'black 'white))
    (Stack 3 (list 'white 'white 'white))
    (Stack 1 (list 'black))
    (Stack 1 (list 'black))
    (Stack 1 (list 'black))))
  'black) 80)


    
;;tie
(game-image
 (Game
  (Board
   (list
    (Stack 6 (list 'black 'white 'white 'black 'black 'black))
    (Stack 6 (list 'black 'white 'black 'black 'black 'white))
    (Stack 6 (list 'white 'black 'white 'black 'black 'white))
    (Stack 6 (list 'white 'black 'black 'white 'white 'white))
    (Stack 6 (list 'black 'black 'black 'white 'black 'black))
    (Stack 6 (list 'white 'white 'white 'black 'white 'black))
    (Stack 6 (list 'white 'black 'black 'black 'white 'black))))
  'black) 80)



;;ongoing
(game-image
 (Game
  (Board
   (list
    (Stack 6 (list 'black 'white 'white 'black 'black 'black))
    (Stack 5 (list 'white 'black 'black 'black 'white))
    (Stack 4 (list 'white 'black 'black 'white))
    (Stack 1 (list 'white))
    (Stack 3 (list 'white 'black 'black))
    (Stack 4 (list 'white 'black 'white 'black))
    (Stack 5 (list 'black 'black 'black 'white 'black))))
  'black) 80)

;;ongoing new game
(game-image new-game 80)



(test)