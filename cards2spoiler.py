#!/usr/bin/env python2

"""Convert a list of card names (with rarity) to MWS spoiler format"""

# -*- coding: utf-8 -*-

from __future__ import print_function
import sys
from lxml import objectify

def get_card_color(card):
    """Given a card lxml.objectify object, determine the color as named by the
    MWS spoiler format"""
    try:
        if len(card.color) >= 2:
            # More than one color: Gold card
            return 'Gld'
        else:
            return card.color
    except AttributeError:
        # Card has no color: Artifact
        return 'Art'

def get_card(oracle, cardname):
    """Given a cardname, return the oracle data on it"""
    try:
        return filter(lambda c: c.name == cardname, oracle.cards.card)[0]
    except IndexError:
        raise ValueError('No card named "' + cardname + '"')

def get_card_pt(card):
    try:
        return card.pt
    except AttributeError:
        return ''

def card_to_mws(oracle, cardname, rarity=None):
    """Given a card name, create the MWS spoiler for it"""
    #MWS Format example:
    #NB: space after colon is \t
    # Card Name:	Aerie Mystics
    # Card Color:	W
    # Mana Cost:	4W
    # Type & Class:	Creature - Bird Cleric
    # Pow/Tou:	3/3
    # Card Text:	Flying  %1%G%U, %T: Creatures you control gain shroud until end of turn.
    # Flavor Text:
    # Artist:
    # Rarity:		U
    # Card #:		1/145
    if cardname[0:3] in ('C: ', 'U: ', 'R: '):
        rarity = cardname[0]
        cardname = cardname[3:]
    card = get_card(oracle, cardname)
    _name = card.name
    _color = get_card_color(_name)
    _cost = unicode(card.manacost)
    _type = card.type
    _pt = get_card_pt(card)
    #_text = get_card_text(card)
    _text = unicode(card.Text)
    _rarity = rarity or 'C'
    _num = '79/79'
    print('Card Name:	' + _name)
    print('Card Color:	' + _color)
    print('Mana Cost:	' + _cost)
    print('Type & Class:	' + _type)
    print('Pow/Tou:	' + _pt)
    print((u'Card Text:	' + _text).encode('latin-1'))
    print('Flavor Text:	')
    print('Artist:	')
    print('Rarity:	' + _rarity)
    print('Card #:	79/79')

if __name__ == '__main__':
    # NB: cards.xml must be massaged: Rename all <text> tags to <Text> or lxml will eat them
    with open('cards.xml') as f:
        oracle = objectify.fromstring(f.read())

    with open('cardlist.txt') as f:
        for card in f:
            sys.stderr.write(card)
            card_to_mws(oracle, card.rstrip())
