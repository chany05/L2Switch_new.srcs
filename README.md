최종 완성

실행법
1. .sv로 파일 읽어오는 포맷 변경
2. elaborate
3. synth하기 전에 세팅에서 신스 설정 rebuilt or full에서 none으로 변경 -> dataflow보존하기 위함
4. synth 및 impl
5. post-impl-timing 및 functional 시뮬레이션 돌리기
6. 시뮬레이션 기간 정해주기 ->5000us

