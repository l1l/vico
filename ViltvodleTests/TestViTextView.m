#import "TestViTextView.h"

/* Given an input text and location, apply the command keys and check
 * that the result is what we expect.
 */
#define TEST(inText, inLocation, commandKeys, outText, outLocation)          \
	[vi setString:inText];                                               \
	[vi setCaret:inLocation];                                            \
	[vi input:commandKeys];                                              \
	STAssertEqualObjects([[vi textStorage] string], outText, nil);       \
	STAssertEquals([vi caret], (NSUInteger)outLocation, nil);

/* motion commands don't alter the text */
#define MOVE(inText, inLocation, commandKeys, outLocation) \
        TEST(inText, inLocation, commandKeys, inText, outLocation)

#define DUMMY	/* workaround for syntax highlighting */

@implementation TestViTextView

- (void)setUp
{
	vi = [[ViTextView alloc] initWithFrame:NSMakeRect(0, 0, 320, 200)];
	parser = [[ViParser alloc] initWithDefaultMap:[ViMap normalMap]];
	[[vi layoutManager] replaceTextStorage:[[ViTextStorage alloc] init]];
	[vi initEditorWithDelegate:nil viParser:parser];
}

- (void)test001_AllocateTextView		{ STAssertNotNil(vi, nil); }
- (void)test002_SetString			{ [vi setString:@"sample"]; STAssertEqualObjects([[vi textStorage] string], @"sample", nil); }

- (void)test010_InsertText			{ TEST(@"abc def", 3, @"i qwerty", @"abc qwerty def", 10); }
- (void)test010_InsertTextAndEscape		{ TEST(@"abc def", 3, @"i qwerty\x1b", @"abc qwerty def", 9); }
- (void)test011_InsertMovesBackward		{ TEST(@"abc def", 3, @"i\x1b", @"abc def", 2); }
- (void)test012_ChangeWord			{ TEST(@"abc\ndef", 1, @"cwcb\x1b", @"acb\ndef", 2); }
- (void)test013_ChangeWordAndPut		{ TEST(@"abc def", 0, @"cwapa\x1b$p", @"apa defabc", 7); }
- (void)test014_AppendText			{ TEST(@"abc", 2, @"adef\x1b", @"abcdef", 5); }
- (void)test015_RepeatAppendText		{ TEST(@"abc", 1, @"adef\x1b.", @"abdefdefc", 7); }
- (void)test016_RepeatInsertText		{ TEST(@"abc", 2, @"idef\x1b.", @"abdedeffc", 6); }
- (void)test017_InsertAtBOLAndRepeat		{ TEST(@"abc", 2, @"I+\x1bll.", @"++abc", 0); }
- (void)test017_InsertAtBOLAndRepeat2		{ TEST(@"abc", 2, @"I#\x1bll.", @"##abc", 0); }
- (void)test018_AppendAtEOLAndRepeat		{ TEST(@"abc", 0, @"A!\x1bhh.", @"abc!!", 4); }
- (void)test019_InsertEmptyTextAndRepeat	{ TEST(@"abc", 2, @"i\x1b.i", @"abc", 0); }

- (void)test020_DeleteForward			{ TEST(@"abcdef", 0, @"x", @"bcdef", 0); }
- (void)test021_DeleteForwardAtEol		{ TEST(@"abc\ndef", 2, @"x", @"ab\ndef", 1); }
- (void)test022_DeleteForewardWithCount		{ TEST(@"abcdef", 1, @"3x", @"aef", 1); }
- (void)test023_DeleteForwardWithLargeCount	{ TEST(@"abcdef\nghi", 4, @"33x", @"abcd\nghi", 4); }
- (void)test024_DeleteForwardAndPut		{ TEST(@"abc", 0, @"xlp", @"bca", 2); }
- (void)test025_RepeatDeleteForward		{ TEST(@"abcdef", 0, @"x..", @"def", 0); }
- (void)test026_DeleteRightAtEOL		{ TEST(@"x", 0, @"dl", @"", 0); }

- (void)test030_DeleteBackward			{ TEST(@"abcdef", 3, @"X", @"abdef", 2); }
- (void)test031_DeleteBackwardAtBol		{ TEST(@"abcdef", 0, @"X", @"abcdef", 0); }
- (void)test032_DeleteBackwardWithCount		{ TEST(@"abcdef", 5, @"4X", @"af", 1); }
- (void)test033_DeleteBackwardWithLargeCount	{ TEST(@"abcdef", 2, @"7X", @"cdef", 0); }
- (void)test034_DeleteBackwardAndPut		{ TEST(@"abc", 1, @"Xlp", @"bca", 2); }

- (void)test040_WordForward			{ MOVE(@"abc def", 0, @"w", 4); }
- (void)test041_WordForwardFromBlanks		{ MOVE(@"   abc def", 0, @"w", 3); }
- (void)test042_WordForwardToNonword		{ MOVE(@"abc() def", 0, @"w", 3); }
- (void)test043_WordForwardFromNonword		{ MOVE(@"abc() def", 3, @"w", 6); }
- (void)test044_WordForwardAcrossLines		{ MOVE(@"abc\n def", 2, @"w", 5); }
- (void)test045_WordForwardAtEOL		{ MOVE(@"abc def", 4, @"w", 6); }
- (void)test046_TwoWordsForward			{ MOVE(@"abc def ghi", 0, @"2w", 8); }

- (void)test050_DeleteWordForward		{ TEST(@"abc def", 0, @"dw", @"def", 0); }
- (void)test051_DeleteWordForward2		{ TEST(@"abc def", 1, @"dw", @"adef", 1); }
- (void)test052_DeleteWordForward3		{ TEST(@"abc def", 4, @"dw", @"abc ", 3); }
- (void)test053_DeleteWordForwardAtEol		{ TEST(@"abc def\nghi", 4, @"dw", @"abc \nghi", 3); }
- (void)test054_DeleteWordForwardAtEmptyLine	{ TEST(@"\nabc", 0, @"dw", @"abc", 0); }
- (void)test055_DeleteWordForwardToNonword	{ TEST(@"abc:def", 0, @"dw", @":def", 0); }

- (void)test060_GotoColumnZero			{ MOVE(@"abc def", 4, @"0", 0); }
- (void)test061_GotoColumnZeroWthLeadingBlanks	{ MOVE(@"    def", 4, @"0", 0); }
- (void)test062_GotoLastLine			{ MOVE(@"abc\ndef\nghi", 5, @"G", 8); }
- (void)test062_GotoLastLine2			{ MOVE(@"abc\ndef\nghi\n", 5, @"G", 8); }
- (void)test062_GotoLastLine3			{ MOVE(@"abc\ndef\nghi\n\n", 5, @"G", 12); }
- (void)test063_GotoFirstLine			{ MOVE(@"abc\ndef\nghi", 5, @"1G", 0); }
- (void)test064_GotoSecondLine			{ MOVE(@"abc\ndef\nghi", 7, @"2G", 4); }
- (void)test065_GotoBeyondLastLine		{ MOVE(@"abc\ndef\nghi", 2, @"220G", 2); }
- (void)test066_GotoEndOfLine			{ MOVE(@"abc def\nghi\n", 2, @"$", 6); }
- (void)test066_GotoEndOfLine2			{ MOVE(@"abc def\nghi\n", 2, @"2$", 10); }

- (void)test070_DeleteCurrentLine		{ TEST(@"abc\ndef\nghi", 2, @"dd", @"def\nghi", 0); }
- (void)test071_DeleteToColumnZero		{ TEST(@"abc def", 4, @"d0", @"def", 0); }
- (void)test072_DeleteToEOL			{ TEST(@"abc def", 0, @"d$", @"", 0); }
- (void)test073_DeleteLastLine			{ TEST(@"abc\ndef", 5, @"dd", @"abc", 0); }
- (void)test074_DeleteToFirstLine		{ TEST(@"abc\ndef\nghi", 5, @"d1G", @"ghi", 0); }
- (void)test075_DeleteToLastLine		{ TEST(@"abc\ndef\nghi\njkl", 5, @"dG", @"abc", 0); }
- (void)test076_DeleteAndPut			{ TEST(@"abc def", 0, @"dw$p", @"defabc ", 3); }
- (void)test077_DeleteToEOL2			{ TEST(@"abc def", 2, @"D", @"ab", 1); }
- (void)test078_DeleteTwoLines			{ TEST(@"abc\ndef\nghi", 1, @"2dd", @"ghi", 0); }
- (void)test078_DeleteTwoLines2			{ TEST(@"abc\ndef\nghi", 1, @"d2d", @"ghi", 0); }

- (void)test080_YankWord			{ TEST(@"abc def ghi", 4, @"yw", @"abc def ghi", 4); }
- (void)test080_YankWordAndPaste		{ TEST(@"abc def ghi", 4, @"ywwP", @"abc def def ghi", 8); }
- (void)test081_YankWord2			{ TEST(@"abc def ghi", 8, @"yw0p", @"aghibc def ghi", 1); }
- (void)test082_YankBackwards			{ TEST(@"abcdef", 3, @"y0", @"abcdef", 0); }
- (void)test083_YankBackwardsAndPaste		{ TEST(@"abcdef", 3, @"y0p", @"aabcbcdef", 1); }
- (void)test084_YankWordAndPasteAtEOL		{ TEST(@"abc def", 4, @"yw$p", @"abc defdef", 7); }
- (void)test085_YankLine			{ TEST(@"abc\ndef", 2, @"yy", @"abc\ndef", 2); }
- (void)test086_YankAndPasteLine		{ TEST(@"abc\ndef\nghi", 1, @"yyp", @"abc\nabc\ndef\nghi", 4); }
- (void)test086_YankAndPasteLine2		{ TEST(@"abc\ndef\nghi", 1, @"ylYp", @"abc\nabc\ndef\nghi", 4); }
- (void)test087_YankAndPasteLineBefore		{ TEST(@"abc\ndef\nghi", 5, @"yyP", @"abc\ndef\ndef\nghi", 4); }

- (void)test090_MoveTilChar			{ MOVE(@"abc def ghi", 1, @"tf", 5); }
- (void)test090_MoveTilChar2			{ MOVE(@"abc def abc", 1, @"tc", 1); }
- (void)test091_MoveToChar			{ MOVE(@"abc def ghi", 1, @"ff", 6); }
- (void)test091_MoveToChar2			{ MOVE(@"abc def abc", 1, @"fb", 9); }
- (void)test092_DeleteToChar			{ TEST(@"abc def abc", 1, @"dfe", @"af abc", 1); }
- (void)test093_MoveToCharWithCount		{ MOVE(@"abc abc abc", 0, @"2fa", 8); }
- (void)test094_DeleteToCharWithCount		{ TEST(@"abc abc abc", 0, @"d2fa", @"bc", 0); }
- (void)test095_DeleteTilCharWithCount		{ TEST(@"abc abc abc", 0, @"d2ta", @"abc", 0); }
- (void)test096_RepeatMoveTilChar		{ MOVE(@"abc abc abc", 2, @"ta;", 3); }
- (void)test097_RepeatMoveToChar		{ MOVE(@"abc abc abc", 2, @"fa;", 8); }
- (void)test097_RepeatMoveToChar2		{ MOVE(@"abc abc abc abc", 2, @"fa2;", 12); }
- (void)test097_DeleteToRepeatedMove		{ TEST(@"abc abc abc abc", 2, @"fad2;", @"abc bc", 4); }
- (void)test097_DeleteToRepeatedMove2		{ TEST(@"abc abc abc abc", 2, @"fa2d;", @"abc bc", 4); }
- (void)test098_ChangeToChar			{ TEST(@"abc abc abc", 0, @"ct ABC\x1bw", @"ABC abc abc", 4); }
- (void)test099_RepeatChangeToChar		{ TEST(@"abc abc abc", 0, @"ct ABC\x1bw.", @"ABC ABC abc", 6); }
- (void)test099_MoveToCharFail			{ MOVE(@"", 0, @"fo", 0); }
- (void)test099_MoveBackToCharFail		{ MOVE(@"", 0, @"Fo", 0); }

- (void)test100_WordBackward			{ MOVE(@"abcdef", 4, @"b", 0); }
- (void)test100_WordBackward2			{ MOVE(@"abc def", 4, @"b", 0); }
- (void)test100_WordBackward3			{ MOVE(@"abc def ghi", 8, @"b", 4); }
- (void)test100_WordBackward4			{ MOVE(@"<abc>def", 4, @"b", 1); }
- (void)test100_WordBackward5			{ MOVE(@"<abc>def", 5, @"b", 4); }
- (void)test100_WordBackward6			{ MOVE(@"<abc def", 5, @"b", 1); }
- (void)test100_WordBackward7			{ MOVE(@"<abc", 1, @"b", 0); }
- (void)test100_WordBackward8			{ MOVE(@"<abc> def", 6, @"b", 4); }
- (void)test100_WordBackward9			{ MOVE(@"  abc", 2, @"b", 0); }
- (void)test101_TwoWordsBackward		{ MOVE(@"abc def ghi", 8, @"2b", 0); }
- (void)test102_TooManyWordsBackward		{ MOVE(@"abc def ghi", 8, @"3b", 0); }

- (void)test110_MoveDown			{ MOVE(@"abc\ndef", 1, @"j", 5); }
- (void)test111_MoveDownAcrossTab		{ MOVE(@"abcdefghijklmno\n\tabcdef", 10, @"j", 19); }
- (void)test112_MoveToFirstNonspace		{ MOVE(@"   abc", 5, @"_", 3); }
- (void)test112_MoveToFirstNonspace2		{ MOVE(@"   abc", 5, @"^", 3); }
- (void)test113_MoveDownOverRaggedLines		{ MOVE(@"abcdef\nabc\nabcdef", 4, @"jj", 15); }
- (void)test114_MoveDownMultipleLines		{ MOVE(@"abc\ndef\nabc\nabc\ndef", 1, @"3j", 13); }
- (void)test115_MoveUpMultipleLines		{ MOVE(@"abc\ndef\nabc\nabc\ndef", 13, @"3k", 1); }

// The Join command is a mess of special cases...
- (void)test120_JoinLines			{ TEST(@"abc\ndef", 0, @"J", @"abc def", 3); }
- (void)test121_JoinLinesWithWhitespace		{ TEST(@"abc\n\t  def", 0, @"J", @"abc def", 3); }
- (void)test122_JoinEmptyLine			{ TEST(@"abc\n\ndef", 0, @"J", @"abc\ndef", 2); }
- (void)test123_JoinFromEmptyLine		{ TEST(@"\ndef", 0, @"J", @"def", 2); }
- (void)test123_JoinFromEmptyLine2		{ TEST(@"\r\ndefghi", 0, @"J", @"defghi", 5); }
- (void)test124_JoinFromLineEndingWithSpaces	{ TEST(@"abc   \ndef", 0, @"J", @"abc   def", 5); }
- (void)test125_JoinFromFinishedSentence	{ TEST(@"abc.\ndef", 0, @"J", @"abc.  def", 4); }
- (void)test125_JoinFromFinishedSentence2	{ TEST(@"abc!\n  def", 0, @"J", @"abc!  def", 4); }
- (void)test125_JoinFromFinishedSentence3	{ TEST(@"abc?\n   def", 0, @"J", @"abc?  def", 4); }
- (void)test126_JoinLineStartingWithParen	{ TEST(@"abc\n)def", 0, @"J", @"abc)def", 2); }

- (void)test130_ReplaceChar			{ TEST(@"abc def", 2, @"rx", @"abx def", 2); }

- (void)test140_BigwordForward			{ MOVE(@"abc=def ghi", 0, @"W", 8); }
- (void)test141_BigwordForwardSpace		{ MOVE(@"abc     ghi", 3, @"W", 8); }
- (void)test142_BigwordBackward			{ MOVE(@"abc=def ghi", 8, @"B", 0); }
- (void)test143_DeleteBigwordBackward		{ TEST(@"abc=def ghi", 8, @"dB", @"ghi", 0); }
- (void)test144_TwoBigwordsForward		{ MOVE(@"abc=def ghi jkl", 0, @"2W", 12); }
- (void)test145_TwoBigwordsBackward		{ MOVE(@"abc=def ghi jkl", 12, @"2B", 0); }

- (void)test150_EndOfWord			{ MOVE(@"abc def", 0, @"e", 2); }
- (void)test151_EndOfWordFromBlanks		{ MOVE(@"   abc def", 0, @"e", 5); }
- (void)test152_EndOfWordToNonword		{ MOVE(@"a_b() def", 0, @"e", 2); }
- (void)test153_EndOfWordFromNonword		{ MOVE(@"a_b() def", 3, @"e", 4); }
- (void)test154_DeleteToEndOfWordToNonword	{ TEST(@"abc:def", 0, @"de", @":def", 0); }
- (void)test155_EndOfBigword			{ MOVE(@"abc:def ghi", 0, @"E", 6); }
- (void)test156_EndOfBigwordFromBlanks		{ MOVE(@"   abc:def ghi", 0, @"E", 9); }
- (void)test156_EndOfBigwordFromNonword		{ MOVE(@"abc:def ghi", 3, @"E", 6); }
- (void)test157_DeleteToEndOfBigwordToNonword	{ TEST(@"abc:def ghi", 0, @"dE", @" ghi", 0); }
- (void)test158_DeleteToEndOfWordFromBlanks	{ TEST(@"abc    def", 4, @"de", @"abc ", 3); }

- (void)test160_DeleteAndUndo			{ TEST(@"abc def", 2, @"xu", @"abc def", 2); }
- (void)test161_InsertAndUndo			{ TEST(@"abc def", 2, @"i ghi\x1bu", @"abc def", 2); }
// the 'a' command is the only exception to caret location after undo, but actually
// vim differs from nvi here and just places the caret at the beginning of the changed text, like 'i'
//- (void)test162_AppendAndUndo			{ TEST(@"abc def", 2, @"a ghi\x1bu", @"abc def", 2); }
- (void)test162_AppendToEmptyLineAndUndo	{ TEST(@"", 0, @"aabc\x1bu", @"", 0); }
- (void)test162_AppendAtEOLAndUndo		{ TEST(@"abc def", 2, @"A ghi\x1bu", @"abc def", 6); }
- (void)test162_AppendAtEOToEmptyLineLAndUndo	{ TEST(@"", 0, @"Aabc\x1bu", @"", 0); }
- (void)test163_UndoRedo			{ [parser setNviStyleUndo:YES]; TEST(@"abc def", 0, @"xxxxuu", @"def", 0); }
// XXX: disabled for now, error in test code
//- (void)test164_RepeatUndo			{ TEST(@"abc def", 0, @"xxxxu..", @"bc def", 0); }
//- (void)test165_RepeatRedo			{ TEST(@"abc def", 0, @"xxxxu..u.", @" def", 0); }
//- (void)test166_UndoAndRedoEdit			{ TEST(@"ab cd ef gh", 0, @"ix\x1bw.uw.", @"xab cd xef gh", 7); }

- (void)test170_ShiftLineRight			{ TEST(@"abc\ndef", 0, @">>", @"\tabc\ndef", 1); }
- (void)test171_ShiftTwoLinesRight		{ TEST(@" abc\n\tdef\nghi", 0, @"2>>", @"\t abc\n\t\tdef\nghi", 1); }
- (void)test172_ShiftThreeLinesRight		{ TEST(@" abc\n\tdef\nghi\njkl", 0, @"3>>", @"\t abc\n\t\tdef\n\tghi\njkl", 1); }
- (void)test173_ShiftLineLeft			{ TEST(@"\t\tabc\ndef", 3, @"<<", @"\tabc\ndef", 2); }
- (void)test174_ShiftTwoLinesLeft		{ TEST(@" abc\n\tdef\nghi", 2, @"2<<", @"abc\ndef\nghi", 1); }
- (void)test175_ShiftLineLeftAtColumn0		{ TEST(@"abc\n\tdef", 4, @"<<", @"abc\ndef", 4); }

- (void)test180_OpenLineAbove			{ TEST(@"abc\ndef", 4, @"Oxxx\x1b", @"abc\nxxx\ndef", 6); }
- (void)test181_DeleteToChar			{ TEST(@"abc def ghi", 0, @"df ", @"def ghi", 0); }
- (void)test182_DeleteToCharAndRepeat		{ TEST(@"abc def ghi", 0, @"df .", @"ghi", 0); }

- (void)test190_SubstLine			{ TEST(@"abc\ndef\nghi", 5, @"Sapa\x1b", @"abc\napa\nghi", 6); }
- (void)test191_SubstLastLine			{ TEST(@"abc\ndef\nghi", 8, @"Sapa\x1b", @"abc\ndef\napa", 10); }

- (void)test200_MoveBackwardTilChar		{ MOVE(@"abc def ghi", 8, @"Tf", 7); }
- (void)test200_MoveBackwardTilChar2		{ MOVE(@"abc def abc", 3, @"Tc", 3); }
- (void)test201_MoveBackwardToChar		{ MOVE(@"abc def ghi", 8, @"Ff", 6); }
- (void)test201_MoveBackwardToChar2		{ MOVE(@"abc def abc", 9, @"Fb", 1); }
- (void)test202_DeleteBackwardToChar		{ TEST(@"abc def abc", 9, @"dFe", @"abc dbc", 5); }
- (void)test203_MoveBackwardToCharWithCount	{ MOVE(@"abc abc abc", 10, @"2Fa", 4); }
- (void)test204_DeleteBackwardToCharWithCount	{ TEST(@"abc abc abc", 10, @"d2Fa", @"abc c", 4); }
- (void)test205_DeleteBackwardTilCharWithCount	{ TEST(@"abc abc abc", 10, @"d2Ta", @"abc ac", 5); }
- (void)test206_RepeatMoveBackwardTilChar	{ MOVE(@"abc abc abc", 7, @"Ta;", 5); }
- (void)test207_RepeatMoveBackwardToChar	{ MOVE(@"abc abc abc", 7, @"Fa;", 0); }
- (void)test208_RepeatOtherDirection		{ MOVE(@"abc abc abc", 0, @"fa;,", 4); }

// - (void)test210_FindForward			{ MOVE(@"abc def ghi", 0, @"/g<cr>", 8); }

- (void)test220_ChangeWordAtEnd			{ TEST(@"apa", 0, @"cwb<esc>", @"b", 0); }
- (void)test220_ChangeWordAndRepeatNearEnd	{ TEST(@"apa\napa", 0, @"cwb<esc>j.", @"b\nb", 2); }

- (void)test230_UpperCaseWord			{ TEST(@"abc def ghi", 0, @"gUw", @"ABC def ghi", 0); }
- (void)test231_UpperCaseTwoWords		{ TEST(@"abc def ghi", 0, @"2gUw", @"ABC DEF ghi", 0); }
- (void)test232_LowerCaseWord			{ TEST(@"ABC DEF GHI", 0, @"guw", @"abc DEF GHI", 0); }
- (void)test233_LowerCaseTwoWords		{ TEST(@"ABC DEF GHI", 0, @"2guw", @"abc def GHI", 0); }
- (void)test234_UpperCaseUnicode		{ TEST(@"ÅäöéÉ", 0, @"gUU", @"ÅÄÖÉÉ", 0); }

- (void)test240_InsertMultipliedText		{ TEST(@"", 0, @"5ix<esc>", @"xxxxx", 4); }
- (void)test241_InsertMultipliedText2		{ TEST(@"", 0, @"5iabc<esc>", @"abcabcabcabcabc", 14); }
- (void)test242_InsertMultipliedText3		{ TEST(@"", 0, @"ix<esc>""4.", @"xxxxx", 3); }
- (void)test243_RepeatInsertMultipliedText	{ TEST(@"x", 0, @"5ab<esc>.", @"xbbbbbbbbbb", 10); }
- (void)test244_RepeatTwiceInsertMultipliedText	{ TEST(@"x", 0, @"5ab<esc>..", @"xbbbbbbbbbbbbbbb", 15); }
//- (void)test245_OpenWithMultipliedText		{ TEST(@"abc\n", 1, @"3Odef\x1b", @"def\ndef\ndef\nabc\n", 10); }

@end
